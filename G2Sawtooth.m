fclose('all'); clear all; close all;

dat = load(fullfile('data','Tobii sawtooth','100Hz','livedata.mat'));
dat2= load(fullfile('data','Tobii sawtooth','50Hz','livedata.mat'));
intervals  = [4999 5036];
intervals2 = [ 685  703];

colors = [
         0    0.4470    0.7410
    0.9290    0.6940    0.1250
    ];

ylims = {[-5.3 -1.8], [-1.1 2.4]
         [-4.1 -1.9], [-11.2 -9]
         [3.3 3.5]  , [3.7 3.9]
         };

for p=1:2
    if p==2
        tdat = dat;
        ival = intervals;
        lbl = '100 Hz';
    else
        tdat = dat2;
        ival = intervals2;
        lbl = '50 Hz';
    end
    for q=1:3
        ax(q,p)=subplot(3,2,q*2+(p-2));
        hold on
        switch q
            case 1
                tsl = tdat.eye.left.ts;
                datl = tdat.eye.left.azi;
                tsr = tdat.eye.right.ts;
                datr = tdat.eye.right.azi;
                tit = 'Azimuth';
                ylab= 'Gaze position (°)';
            case 2
                tsl = tdat.eye.left.ts;
                datl = tdat.eye.left.ele;
                tsr = tdat.eye.right.ts;
                datr = tdat.eye.right.ele;
                tit = 'Elevation';
                ylab= 'Gaze position (°)';
            case 3
                tsl = tdat.eye.left.ts;
                datl = tdat.eye.left.pd;
                tsr = tdat.eye.right.ts;
                datr = tdat.eye.right.pd;
                tit = 'Pupil size';
                ylab= 'Pupil diameter (mm)';
        end
        tsl = tsl(ival(1):ival(2))*1000;
        datl = datl(ival(1):ival(2));
        tsr = tsr(ival(1):ival(2))*1000;
        datr = datr(ival(1):ival(2));
        tsr = tsr-tsl(1);   % not going to assume timestamps for left and right eye are the same, though i think they always are
        tsl = tsl-tsl(1);
        if tsr(1)<0
            tsl = tsl-tsr(1);
            tsr = tsr-tsr(1);
        end
        
        h1 = plot(tsl,datl,'LineWidth',1.2,'Color',colors(1,:));
        h2 = plot(tsr,datr,'LineWidth',1.2,'Color',colors(2,:));
        
        xlim([0 max([tsl(end) tsr(end)])])
        if q==1
            axis ij
        end
        ylim(ylims{q,p});
        
        ht=title(tit);
        ht.Position(1) = ax(q,p).XLim(1);
        ht.HorizontalAlignment = 'left';
        if q==1
            ht2 = text(0,ax(q,p).YLim(1)-diff(ax(q,p).YLim)*.28,lbl,'FontWeight','bold','FontSize',11);
        end
        
        if p==1
            ylabel(ylab)
        end
        if q==3
            xlabel('Time (ms)')
        end
        ax(q,p).XTick = 0:70:360;
        if q==3 && p==1
            [hl,lines] = legend([h1 h2],'left','right','Location','NorthEast','Box','off');
            lines(3).XData(1) = .36;
            lines(5).XData(1) = .36;
            hl.Position(1) = .095;
            hl.Position(2) = .085;
        end
    end
    
    % fix up y-axis labels
    yl=[ax(:,p).YLabel];
    [yl.Units] = deal('pixels');
    pos = cat(1,yl.Position);
    pos(:,1) = min(pos(:,1))-4;             % set to furthest, add bit of margin
    pos = num2cell(pos,2);
    [yl.Position] = pos{:};
end
pos  = cat(1,ax.Position);
hgap = pos(4,1)-pos(3,1)-pos(3,3);
% adjust hori
for v=4:6
    ax(v).Position(1) = ax(v-3).Position(1)+ax(v-3).Position(3)+hgap*.6;
end
for v=1:6
    ax(v).Position(2) = pos(v,2)-.03;
end

print(fullfile(cd,'output','tobiiSawTooth'),'-depsc')