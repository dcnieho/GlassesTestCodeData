fclose('all'); clear all; close all;

fixCodeDir = 'C:\dat\projects\glasses test\validationCodingAdjust\output';

[lookup,taskLookup] = getLookups;

deg2cm        = 2.681;
targetPos = [
    -17  11
      0  11
     17  11
    -17   0
      0   0
     17   0
    -17 -11
      0 -11
     17 -11
    ]*deg2cm;

nPoint = 9;
assert(size(targetPos,1)==nPoint);
dist          = 150;    % cm, distance to viewing plane
minConsecData = 100;    % ms

% select bits to plot
ETs     = {'tobii','grip','pupillabs','smi'};

setups  = cellfun(@(x)     lookup{strcmp(    lookup(:,1),x),3},ETs,'uni',false);

% calculate or load per-point data quality measures
tasks   = {'validation1','validation2'};
if ~exist('valDataQuality.mat','file')
    load ETdata
    trackers    = fields(ETdata);
    recordings  = fields(ETdata.(trackers{1})); % all trackers have same recordings
    for t=1:length(trackers)
        qLookup = strcmp(lookup(:,1),trackers{t});
        nMinConsecSamp = ceil(lookup{qLookup,4}*minConsecData/1000);
        for r=1:length(recordings)
            for e=1:length(tasks)
                dat = ETdata.(trackers{t}).(recordings{r}).(tasks{e});
                % per fixation, determine position
                if ~isfield(dat,'fix')
                    % we had one uncodable subject, so missing info for
                    % this one. Lets not count as missing either, as there
                    % was data, it was just uninterpretable.
                    assert(isequal({trackers{t},recordings{r},tasks{e}},{'pupillabs','pt2','validation2'}))
                    continue
                end
                for f=size(dat.fix.marks,1):-1:1
                    valDataQuality.(trackers{t}).(recordings{r}).(tasks{e}).fixPos(f,:) = nanmedian([dat.dxCm(dat.fix.marks(f,1):dat.fix.marks(f,2)) dat.dyCm(dat.fix.marks(f,1):dat.fix.marks(f,2))]);
                end
                % per fixation target point, compute data quality
                for p=1:nPoint
                    % get samples for fixations marked as belonging to this
                    % target. Take whole stream, make it nan if not during
                    % the fixation(s) of interest
                    iPointData  = find(dat.fix.target==p);
                    qTheseFix   = bounds2bool(dat.fix.marks(iPointData,1),dat.fix.marks(iPointData,2),length(dat.dxCm));
                    theseDat    = [dat.dxCm dat.dyCm];
                    theseDat(~qTheseFix,:) = nan;
                    
                    % remove samples with too low confidence
                    
                    confLim = lookup{qLookup,2};
                    theseDat(dat.confidence<=confLim,:) = nan;
                    
                    % determine summed duration of intervals
                    dur = dat.gazeTs(dat.fix.marks(iPointData,2))-dat.gazeTs(dat.fix.marks(iPointData,1));
                    fs  = lookup{qLookup,5};
                    nExpect = sum(floor(dur*fs/1000));
                    nSamp = sum(dat.fix.marks(iPointData,2)-dat.fix.marks(iPointData,1)+1);
                    assert(nSamp<=nExpect+10);  % correct for floor and otherwise slightly off expectations apparently
                    if nExpect<nSamp
                        nExpect = nSamp;
                    end
                    
                    % ensure there is a long enough bit of data
                    [on,off]    = bool2bounds(any(~isnan(theseDat),2));
                    if any(off-on+1>=nMinConsecSamp)
                        % get number of valid samples per fix
                        nValidSamp  = cellfun(@(x) sum(qTheseFix(x(1):x(2))),num2cell(dat.fix.marks(iPointData,:),2));
                        
                        % 1. accuracy (weighted sum of median offset per fixation,
                        % weighted by number of samples in each fixation)
                        % first determine offsets
                        fixPos  = valDataQuality.(trackers{t}).(recordings{r}).(tasks{e}).fixPos(iPointData,:);
                        datCm   = [fixPos repmat(dist,size(fixPos,1),1)];
                        refCm   = repmat([targetPos(p,:) dist],size(fixPos,1),1);
                        off     = angleBetween(datCm,refCm);
                        % combine in weighted sum
                        acc         = sum(off.*nValidSamp)/sum(nValidSamp);
                        
                        % 2. RMS, do correctly by using angleBetween
                        datCm       = [theseDat(1:end-1,:) repmat(dist,size(theseDat,1)-1,1)];
                        refCm       = [theseDat(2:end  ,:) repmat(dist,size(theseDat,1)-1,1)];
                        theseDist   = angleBetween(datCm,refCm);
                        RMSxy       = sqrt(nanmean(theseDist.^2));
                        
                        % 3. STD
                        % pooled STD: compute STD for each fixation, then
                        % pool weighting by number of valid samples
                        clear temp
                        for i=length(iPointData):-1:1
                            % do this properly, using angle between, and
                            % not using std of distances from centroid, but
                            % std of x and y (signed) separately, then
                            % combine into 2D
                            theDat   = theseDat(dat.fix.marks(iPointData(i),1):dat.fix.marks(iPointData(i),2),:);
                            centroid = nanmean(theDat,1);
                            start    = repmat([centroid dist],size(theDat,1),1);
                            datCm    = start; datCm(:,1) = theDat(:,1);
                            x = angleBetween(datCm,repmat([centroid dist],size(theDat,1),1)).*sign(theDat(:,1)-centroid(1));
                            datCm    = start; datCm(:,2) = theDat(:,2);
                            y = angleBetween(datCm,repmat([centroid dist],size(theDat,1),1)).*sign(theDat(:,2)-centroid(2));
                            temp(i)  = sqrt(sum(x.^2)/(sum(~isnan(x))-1) + sum(y.^2)/(sum(~isnan(y))-1));
                        end
                        stdxy   = sqrt(sum((nValidSamp.'-1).*temp.^2)/(sum(nValidSamp)-numel(temp)));
                        
                        % 4. data loss
                        nValid  = sum(~isnan(theseDat(qTheseFix,1)));
                        loss    = (1-nValid/nExpect)*100;
                    else
                        acc     = nan;
                        RMSxy   = nan;
                        stdxy   = nan;
                        if ismember(trackers{t},{'eyerec','grip'}) && strcmp(recordings{r},'aw1') && strcmp(tasks{e},'validation1')
                            % i forgot to instruct participant for this
                            % recording to look at all nine dots. Don't
                            % count that as missing
                            loss    = 0;
                        else
                            loss    = 100;    % mark as fully lost
                        end
                    end
                    % store
                    valDataQuality.(trackers{t}).(recordings{r}).(tasks{e}).acc(p)     = acc;
                    valDataQuality.(trackers{t}).(recordings{r}).(tasks{e}).RMSxy(p)   = RMSxy;
                    valDataQuality.(trackers{t}).(recordings{r}).(tasks{e}).stdxy(p)   = stdxy;
                    valDataQuality.(trackers{t}).(recordings{r}).(tasks{e}).loss(p)    = loss;
                end
            end
        end
    end
    save valDataQuality valDataQuality
else
    load valDataQuality
end

assert(length(ETs)==4)
% collect data
[dat.offset,dat.RMSxy,dat.stdxy,dat.dataLoss] = deal(cell(2,length(ETs)));
for e=length(tasks):-1:1
    for t=1:length(ETs)
        % collect data from all recordings
        recordings = fieldnames(valDataQuality.(ETs{t}));
        [a,b,c,d] = deal([]);
        for r=1:length(recordings)
            if ~isfield(valDataQuality.(ETs{t}).(recordings{r}),tasks{e})
                assert(isequal({ETs{t},recordings{r},tasks{e}},{'pupillabs','pt2','validation2'}))
                a = [a; nan(1,nPoint)];
                b = [b; nan(1,nPoint)];
                c = [c; nan(1,nPoint)];
                d = [d; nan(1,nPoint)];
            else
                a = [a; valDataQuality.(ETs{t}).(recordings{r}).(tasks{e}).acc];
                b = [b; valDataQuality.(ETs{t}).(recordings{r}).(tasks{e}).RMSxy];
                c = [c; valDataQuality.(ETs{t}).(recordings{r}).(tasks{e}).stdxy];
                d = [d; valDataQuality.(ETs{t}).(recordings{r}).(tasks{e}).loss];
            end
        end
        dat.offset{e,t} = a;
        dat.RMSxy{e,t} = b;
        dat.stdxy{e,t} = c;
        dat.dataLoss{e,t} = d;
    end
end
vars = {'offset','RMSxy','stdxy','dataLoss'};
varsNice = {'Accuracy (Deviation)','Precision (RMS-S2S)','Precision (STD)','Data loss'};
varsLbl  = {'Deviation (°)','RMS-S2S (°)','STD (°)','Track loss (%)'};
symbs   = 'ods^';   % per ET

if 1
    % compare data quality for validation 1 and validation 2
    % 1. average over points and recordings
    for d=1:length(vars)
        datA.(vars{d})      = cellfun(@(x) nanmean(x(:)),dat.(vars{d}));
        numels              = cellfun(@(x) sum(~isnan(x(:))),dat.(vars{d}));
        datA.CI.(vars{d})   = arrayfun(@(x,n) nanstd(x{1}(:))/sqrt(n)*tinv(.975,n-1),dat.(vars{d}),numels);
    end
    
    ranges = {[0 13],[0 1.05],[0 1],[0 30]};
    
    f=figure('Renderer','Painters');
    f.Position(3) = f.Position(3)*0.75;
    f.Position(4) = f.Position(4)*1.0;
    for d=1:length(vars)
        ax(d)=subplot(2,2,d);
        
        h=errorbar(datA.(vars{d}),datA.CI.(vars{d}),'-o','LineWidth',1.2);
        for l=1:length(h)
            h(l).Marker = symbs(l);
            h(l).MarkerFaceColor = h(l).Color;
            h(l).MarkerSize = 4;
        end
        
        xlim([0.8 2.2])
        ylim(ranges{d})
        
        ht = title(varsNice{d});
        ht.Position(1) = ax(d).XLim(1);
        ht.HorizontalAlignment = 'left';
        
        ylabel(varsLbl{d})
        
        ax(d).XTick = 1:2;
        if ismember(d,[3 4])
            xlabel('Validation moment')
            ax(d).XTickLabel = {'Recording start','Recording end'};
        else
            ax(d).XTickLabel = [];
        end
        if d==1
            [hl,lines] = legend(h,setups{:},'Location','NorthWest','Box','off');
            for l=5:8
                lines(l).Children.Children(2).XData(1) = .25;
                lines(l).Children.Children(1).XData(1) = mean(lines(l).Children.Children(2).XData);
            end
            hl.Position(1) = .10;
            hl.Position(2) = .79;
        end
        if ismember(d,[2:3])
            ax(d).YRuler.TickLabelFormat = '%.1f';
        end
        ax(d).Box = 'off';
    end
    
    pos = cat(1,ax.Position);
    gap = pos(1,2)-pos(3,2)-pos(3,4);
    for p=3:4
        ax(p).Position(2) = ax(p).Position(2)+gap*.4;
    end
    
    drawnow;
    ax(1).YAxis.Label.Position(1) = ax(3).YAxis.Label.Position(1);
    
    print(fullfile(cd,'output','9point_averaged_DQ'),'-depsc')
end

if 1
    switch 1
        case 1
            % use only first validation moment
            useMoment = 1;
            momLbl = 'atStart';
        case 2
            % use only second validation moment
            useMoment = 2;
            momLbl = 'atEnd';
        case 3
            % average validation moments
            useMoment = [1 2];
            momLbl = 'averaged';
    end
    % compare data quality for fixation positions, averaged over validation
    % moment.
    for d=1:length(vars)
        datA.(vars{d}) = cellfun(@nanmean,dat.(vars{d}),'uni',false);
        datA.(vars{d}) = permute(cat(3,cat(1,datA.(vars{d}){1,:}),cat(1,datA.(vars{d}){2,:})),[3 2 1]);
        if isscalar(useMoment)
            % use only first validation moment
            datA.(vars{d}) = squeeze(datA.(vars{d})(useMoment,:,:));
        else
            % average validation moments
            datA.(vars{d}) = squeeze(mean(datA.(vars{d})(useMoment,:,:),1));
        end
    end
    
    colAxTickFmt = {'%1.0f°','%.1f°','%.1f°','%2d%%'};
    colAxTicks   = {[],[.1:.3:1.6],[],[]};
    
    f=figure('Renderer','Painters');
    f.Position(2) = 55;
    f.Position(3) = f.Position(3)*1.5;
    f.Position(4) = f.Position(4)*0.5*4;
    colors = rgb2hsl([
         46  17  0
        254 138 72
        ]);
    for d=1:length(vars)
        theMax   = max(datA.(vars{d})(:));
        theMin   = min(datA.(vars{d})(:));
        theRange = theMax-theMin;
        for t=1:length(ETs)
            ax(d,t) = subplot(4,4,(d-1)*4+t);
            
            for p=1:nPoint
                clr = hsl2rgb(interp1(linspace(0,1,size(colors,1)),colors,(datA.(vars{d})(p,t)-theMin)/theRange))./255;
                [x,y] = ind2sub([3 3],p);
                patch(x+[-.5 .5 .5 -.5],y+[-.5 -.5 .5 .5],clr,'EdgeColor','none');
                text(x,y,sprintf('%.2f',datA.(vars{d})(p,t)),'HorizontalAlignment','center','VerticalAlignment','middle','Color',[1 1 1])
            end
            hold on
            plot([.5 3.5 nan .5 3.5 nan 1.5 1.5 nan 2.5 2.5],[1.5 1.5 nan 2.5 2.5 nan .5 3.5 nan .5 3.5],'LineWidth',1,'Color',.85*[1 1 1])
            
            xlim([.5 3.5])
            ylim([.5 3.5])
            axis ij
            
            ht = title(setups{t});
            ht.Position(1) = ax(d,t).XLim(1);
            ht.HorizontalAlignment = 'left';
            
            ax(d,t).XTick = 1:3;
            ax(d,t).YTick = 1:3;
            if t==1
                ax(d,t).YTickLabel = {'Top','Middle','Bottom'};
                ax(d,t).YLabel.String = 'Vertical position';
            else
                ax(d,t).YTickLabel = [];
            end
            ax(d,t).XTickLabel = {'Left','Center','Right'};
            if d==length(vars)
                ax(d,t).XLabel.String = 'Horizontal position';
            end
            ax(d,t).Box = 'off';
        end
    end
    drawnow;
    % further plot layouting.
    % 1. first, move axes to make space for color bars and titles
    % 1a. horizontal change in interspacing and location to fit in color
    %     bar
    for d=1:length(vars)
        pos = cat(1,ax(d,1:2).Position);
        hspace = (pos(2:end,1)-(pos(1:end-1,1)+pos(1:end-1,3)))*.5;
        pos = pos(1,:);
        pos(1,1)    = pos(1,1)-.05;
        for t=1:length(ETs)
            ax(d,t).Position = pos;
            pos(1,1)  = pos(1,1)+pos(1,3) + hspace;
        end
    end
    
    % 1b. figure out vertical spacing: less edge space on top and bottom,
    %     more spacing in between to leave room for titles. Also make axes
    %     exactly square
    pos = cat(1,ax(:,1).Position);
    pos(:,4) = pos(:,3);
    space = pos(1:end-1,2)-(pos(2:end,2)+pos(2:end,4));
    spacetop = 1-(pos(1,2)+pos(1,4));
    spacebot = pos(end,2);
    extraspace = (spacetop-.07)+(spacebot-.02);
    space = space+extraspace/(size(pos,1)-1);
    pos(:,2) = flipud(cumsum([0.05; pos(1:end-1,4)+space]));
    for d=1:length(vars)
        for t=1:length(ETs)
            ax(d,t).Position([2 3 4]) = pos(d,[2 3 4]);
        end
    end
    
    % 2. make row titles
    left = ax(1,1).Position(1);
    pos = cat(1,ax(:,1).Position);
    hTop= pos(:,2)+pos(:,4)+.02;
    for d=1:length(vars)
        % convert to position relative to axes
        pos = ax(d,2).Position;
        lims = [ax(d,2).XLim; ax(d,2).YLim];
        range= diff(lims,[],2);
        ax2dat = range.'./pos(3:4);
        off = [left-(pos(1)+pos(3)) hTop(d)-(pos(2)+pos(4))];
        offDat = off.*ax2dat;
        h=text(lims(1,2)+offDat(1),lims(2,1)-offDat(2),varsNice{d},'HorizontalAlignment','left','VerticalAlignment','bottom','Parent',ax(d,2),'FontWeight','bold','FontSize',12);
    end
    
    % make axis, draw boxes
    for d=1:length(vars)
        theMax   = max(datA.(vars{d})(:));
        theMin   = min(datA.(vars{d})(:));
        
        pos = cat(1,ax(d,:).Position);
        cpos = pos(1,:);
        cpos(1) = pos(end,1)+pos(end,3) + hspace(end);
        cpos(3) = pos(end,3)*.2;
        cax = axes('Position',cpos);
        % put value axis only on right
        yyaxis right
        cax.YAxis(1).Visible = 'off';
        cax.YAxis(2).Color = [0 0 0];
        cax.XAxis.Visible = 'off';
        cax.YLim = [theMin theMax];
        cax.XLim = [0 1];
        % draw the heatmap
        steps = linspace(theMin,theMax,64+1);
        for p=1:64
            clr = hsl2rgb(interp1([0 1],colors,p/64))./255;
            patch([0 1 1 0],steps(p+[0 0 1 1]),clr,'EdgeColor','none');
        end
        cax.YAxis(2).TickDirection = 'out';
        cax.YAxis(2).TickLabelFormat = colAxTickFmt{d};
        if ~isempty(colAxTicks{d})
            cax.YAxis(2).TickValues = colAxTicks{d};
        end
    end
    
    % done
    print(fullfile(cd,'output',['9point_DQ_heat_all_' momLbl]),'-depsc')
end