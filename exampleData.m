fclose('all'); clear all; close all;

load ETdata

[lookup,taskLookup] = getLookups;

colors = [
         0    0.4470    0.7410
    0.9290    0.6940    0.1250
    ];

% select bits to plot
switch 1
    case 1
        % example data during 9-point val
        lbl = 'ex_9point';
        what     = {
            'tobii','mn1','validation1',[5.4 8.4]
            'grip' ,'mn2','validation1',[6.45 9.45]
            'pupillabs','mn1','validation1',[6 9]
            'smi'  ,'mn1','validation1',[5.6 8.6]
            };
        lims = [0 3 -20 20];
    case 2
        % example data during baseline, vowel, eyebrows
        lbl = 'ex_smallslip';
        what     = {
            'tobii','mn1',{'baseline','vowels','eyebrows'}
            'grip' ,'mn2',{'baseline','vowels','eyebrows'}
            'pupillabs','mn1',{'baseline','vowels','eyebrows'}
            'smi'  ,'mn1',{'baseline','vowels','eyebrows'}
            };
        lims = [0 nan -10 10];
    case 3
        % example data during glasses movement tasks
        lbl = 'ex_largeslip';
        what     = {
            'tobii','mn2',{'mov_hor','mov_ver','mov_depth'}
            'grip' ,'mn2',{'mov_hor','mov_ver','mov_depth'}
            'pupillabs','mn1',{'mov_hor','mov_ver','mov_depth'}
            'smi'  ,'mn2',{'mov_hor','mov_ver','mov_depth'}
            };
        lims = {[0 nan -10 10],[0 nan -30 30]};
end

assert(size(what,1)==4)
for p=1:size(what,1)
    ax(p)=subplot(2,2,p);
    hold on
    
    clear taskt
    if iscell(what{p,3})
        % multiple tasks, glue them together
        dat = struct('timestamp',[],'confidence',[],'dxDeg',[],'dyDeg',[]);
        taskt = 0;
        for e=1:length(what{p,3})
            t = ETdata.(what{p,1}).(what{p,2}).(what{p,3}{e}).timestamp;
            if ~isempty(dat.timestamp)
                td = t(1:2)-dat.timestamp(end);
                t = t-td(1)+diff(td);   % add isi
            else
                t = t-t(1);
            end
            dat.timestamp   = [dat.timestamp;  t];
            dat.confidence  = [dat.confidence; ETdata.(what{p,1}).(what{p,2}).(what{p,3}{e}).confidence];
            dat.dxDeg       = [dat.dxDeg;      ETdata.(what{p,1}).(what{p,2}).(what{p,3}{e}).dxDeg];
            dat.dyDeg       = [dat.dyDeg;      ETdata.(what{p,1}).(what{p,2}).(what{p,3}{e}).dyDeg];
            taskt = [taskt t(end)]; %#ok<AGROW>
        end
    else
        dat             = ETdata.(what{p,1}).(what{p,2}).(what{p,3});
        dat.timestamp   = dat.timestamp-dat.timestamp(1);
    end
    
    qLookup = strcmp(lookup(:,1),what{p,1});
    qNaN    = dat.confidence<=lookup{qLookup,2};
    
    plotDat = [dat.timestamp dat.dxDeg -dat.dyDeg];
    plotDat(qNaN,2:3) = nan;
    
    if size(what,2)>3
        qT = plotDat(:,1)>=what{p,4}(1) & plotDat(:,1)<=what{p,4}(2);
        plotDat(~qT,:) = [];
        plotDat(:,1) = plotDat(:,1)-what{p,4}(1);
    end
    
    if exist('taskt','var')
        % indicate task extents
        for t=2:2:length(taskt)
            if t==length(taskt)
                continue;
            end
            patch(taskt(t+[0 1 1 0]),[-1000 -1000 1000 1000],[.8 .8 .8],'LineStyle','none');
        end
    end
    
    h1 = plot(plotDat(:,1),plotDat(:,2),'LineWidth',1.2,'Color',colors(1,:));
    h2 = plot(plotDat(:,1),plotDat(:,3),'LineWidth',1.2,'Color',colors(2,:));
    
    
    if iscell(lims)
        tlims = lims{ceil(p/2)};
    else
        tlims = lims;
    end
    if ~isnan(tlims(2))
        xlim(tlims(1:2))
    else
        xlim(dat.timestamp([1 end]))
    end
    ylim(tlims(3:4))
    axis ij
    
    ht=title(lookup{qLookup,3});
    ht.Position(1) = ax(p).XLim(1);
    ht.HorizontalAlignment = 'left';
    
    if exist('taskt','var') && p==1
        for t=1:length(what{p,3})
            qLbl = strcmp(taskLookup(:,1),what{p,3}{t});
            tLbl = taskLookup{qLbl,2};
            text(mean(taskt(t+[0 1])),tlims(4),tLbl,'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',9)
        end
    end
    
    if ismember(p,[1 3])
        ylabel('Gaze position (°)')
    end
    if ismember(p,[3 4])
        xlabel('Time (s)')
    end
    if p==1
        [hl,lines] = legend([h1 h2],'horizontal','vertical','Location','NorthWest','Box','off');
        lines(3).XData(1) = .36;
        lines(5).XData(1) = .36;
        hl.Position(1) = .073;
        hl.Position(2) = .85;
    end
end

pos  = cat(1,ax.Position);
hgap = pos(2,1)-pos(1,1)-pos(1,3);
vgap = pos(1,2)-pos(3,2)-pos(3,4);
% adjust hori
for v=[2 4]
    ax(v).Position(1) = ax(v-1).Position(1)+ax(v-1).Position(3)+hgap*.6;
end
% adjust vertical
for v=[3 4]
    ax(v).Position(2) = ax(v-2).Position(2)-ax(v-2).Position(4)-vgap*.8;
end

print(fullfile(cd,'output',lbl),'-depsc')