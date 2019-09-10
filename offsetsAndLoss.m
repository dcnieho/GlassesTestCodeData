fclose('all'); clear all; close all;


[lookup,taskLookup] = getLookups;

clrs = [
    255, 225, 25
    0, 130, 200
    245, 130, 48
    60, 180, 75
    230, 190, 255
    70, 240, 240
    128, 0, 0
    0, 0, 128
    128, 128, 128
    ]./255;

% select bits to plot
jitter = .1;
switch 2
    case 1
        % during baseline, vowel, eyebrows
        lbl     = 'offset_loss_small';
        tasks   = {'baseline','vowels','eyebrows'};
        ETs     = {'tobii','grip','pupillabs','smi'};
        lims    = {[0 8],[0 40]};
        figSz   = [1.15 0.7];
        ticks   = {[0:2:8],[0:8:40]};
        xlbl    = 'Facial movement';
        legendx = .085;
        legendy = .72;
    case 2
        % during glasses movement tasks
        lbl     = 'offset_loss_large';
        tasks   = {'baseline','mov_hor','mov_ver','mov_depth'};
        ETs     = {'tobii','grip','pupillabs','smi'};
        lims    = {[0 36],[0 60]};
        figSz   = [1.15 0.7];
        ticks   = {[0:6:36],[0:12:60]};
        xlbl    = 'Eye-tracker movement';
        legendx = .085;
        legendy = .72;
end

setups    = cellfun(@(x)     lookup{strcmp(    lookup(:,1),x),3},ETs,'uni',false);
taskNames = cellfun(@(x) taskLookup{strcmp(taskLookup(:,1),x),2},tasks,'uni',false);

load ETdata

recordings = fieldnames(ETdata.(ETs{1}));
subjs      = unique(cellfun(@(x) x(1:2),recordings,'uni',false));

assert(length(ETs)==4)
for t=1:length(ETs)
    % collect all data
    qLookup = strcmp(lookup(:,1),ETs{t});
    confLim = lookup{qLookup,2};
    offset50{t} = nan(length(subjs),length(tasks));
    loss{t} = nan(length(subjs),length(tasks));
    for p=1:length(tasks)
        for s=1:length(subjs)
            confidence = [];
            errorDeg = [];
            dur      = [];
            for r=1:2
                field = sprintf('%s%d',subjs{s},r);
                confidence = [confidence; ETdata.(ETs{t}).(field).(tasks{p}).confidence];
                errorDeg = [errorDeg; ETdata.(ETs{t}).(field).(tasks{p}).errorDeg];
                dur        = [dur; ETdata.(ETs{t}).(field).(tasks{p}).gazeTs(end)-ETdata.(ETs{t}).(field).(tasks{p}).gazeTs(1)];
            end
            qNaN    = confidence<=confLim;
            errorDeg(qNaN) = [];
            offset50{t}(s,p)= median(errorDeg);
            
            % determine loss. first: number of expected samples
            fs  = lookup{qLookup,5};
            nExpect = sum(floor(dur*fs/1000));
            nValid  = sum(~qNaN);
            assert(length(qNaN)<=nExpect+10);  % correct for floor and otherwise slightly off expectations apparently
            if nExpect<length(qNaN)
                nExpect = length(qNaN);
            end
            loss{t}(s,p)= (1-nValid/nExpect)*100;
        end
    end
end

f=figure('Renderer','Painters');
f.Position(3) = f.Position(3)*figSz(1);
f.Position(4) = f.Position(4)*figSz(2);
nPart = size(offset50{1},1);
nTask = size(offset50{1},2);
jitters = ([1:length(ETs)]-1);
jitters = (jitters-jitters(end)/2)*jitter;
symbs   = 'ods^';
for t=1:2
    if t==1
        mydat = offset50;
    elseif t==2
        mydat = loss;
    end
    ax(t)=subplot(1,2,t);
    hold on
    
    mdat = cellfun(@mean,mydat,'uni',false);
    mdat = cat(1,mdat{:}).'
    ciDat= cellfun(@(x) std(x)/sqrt(nPart)*tinv(.975,nPart-1),mydat,'uni',false);
    ciDat= cat(1,ciDat{:}).';
    xdat = repmat([1:nTask].',1,size(mdat,2))+repmat(jitters,size(mdat,1),1);
    plotSet = {'o','MarkerSize',5};
    
    h=errorbar(xdat,mdat,ciDat,plotSet{:});
    for l=1:length(h)
        h(l).Marker = symbs(l);
        h(l).MarkerFaceColor = h(l).Color;
        h(l).MarkerSize = 5;
        h(l).LineWidth = 1.2;
    end
    
    ylim(lims{t})
    if t==1
        ylabel('Deviation (°)')
    elseif t==2
        ylabel('Data loss (%)')
    end
    ax(t).YTick = ticks{t};
    
    xlim([.4 nTask+.6])
    
    if t==1
        tit = 'Accuracy';
    elseif t==2
        tit = 'Data loss';
    end
    ht=title(tit);
    ht.Position(1) = ax(t).XLim(1);
    ht.HorizontalAlignment = 'left';
    
    xlabel(xlbl)
    ax(t).XTick = 1:length(tasks);
    ax(t).XTickLabel = taskNames;
    ax(t).XTickLabelRotation = 30;
    
    if t==1
        [hl,lines] = legend(h,setups{:},'Location','NorthEast','Box','off');
        for l=5:8
            lines(l).Children.Children(2).XData(1) = .28;
            lines(l).Children.Children(1).XData(1) = mean(lines(l).Children.Children(2).XData);
            lines(l).Children.Children(1).MarkerSize = 4;
        end
        hl.Position(1) = legendx;
        hl.Position(2) = legendy;
    end
end

print(fullfile(cd,'output',lbl),'-depsc')