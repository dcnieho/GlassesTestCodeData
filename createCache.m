fclose('all');

% where to find data
codingFile = fullfile(cd,'data','coding.csv');
inputDir   = fullfile(cd,'data');
fixCodeDir = fullfile(cd,'data','validationCodingAdjust');

% distance to viewing plane
dist    = 150;  % cm

% read coding file, parse
fid    = fopen(codingFile,'rt');
coding = textscan(fid,'%s%s%s%f%f','Delimiter',',','HeaderLines',1);
fclose(fid);

trackers    = unique(coding{1});
recordings  = unique(coding{2});
events      = unique(coding{3});
% i'm just going to assume it is all fine, Thiago's parser has checked the
% coding

% collect eye movement data for each task
ETdata = struct();
for t=1:length(trackers)
    qTrack = strcmp(coding{1},trackers{t});
    tfield = trackers{t};
    if strcmp(tfield,'pupil-labs')
        tfield = 'pupillabs';
    end
    for r=1:length(recordings)
        qRec = strcmp(coding{2},recordings{r});
        fprintf('%s / %s\n',trackers{t},recordings{r});
        % read file
        fid = fopen(fullfile(inputDir,trackers{t},recordings{r},'report.tsv'),'rt');
        data = textscan(fid,'%f%f%f%f%f%f%f%f%f','HeaderLines',1,'CollectOutput',true); data=data{1};
        fclose(fid);
        for e=1:length(events)
            qE   = qTrack & qRec & strcmp(coding{3},events{e});
            assert(sum(qE)==1)
            qDat = data(:,1)>=coding{4}(qE) & data(:,1)<=coding{5}(qE);
            
            ETdata.(tfield).(recordings{r}).(events{e}).device      = trackers{t};
            ETdata.(tfield).(recordings{r}).(events{e}).recoding    = recordings{r};
            ETdata.(tfield).(recordings{r}).(events{e}).event       = events{e};
            ETdata.(tfield).(recordings{r}).(events{e}).stf         = coding{4}(qE);
            ETdata.(tfield).(recordings{r}).(events{e}).etf         = coding{5}(qE);
            ETdata.(tfield).(recordings{r}).(events{e}).frame_idx   = data(qDat,1);
            ETdata.(tfield).(recordings{r}).(events{e}).timestamp   = data(qDat,2);
            ETdata.(tfield).(recordings{r}).(events{e}).confidence  = data(qDat,3);
            ETdata.(tfield).(recordings{r}).(events{e}).errorDeg    = data(qDat,4);
            ETdata.(tfield).(recordings{r}).(events{e}).dxCm        = data(qDat,5);
            ETdata.(tfield).(recordings{r}).(events{e}).dyCm        = data(qDat,6);
            ETdata.(tfield).(recordings{r}).(events{e}).gazeTs      = data(qDat,7);
            ETdata.(tfield).(recordings{r}).(events{e}).gazeX       = data(qDat,8);
            ETdata.(tfield).(recordings{r}).(events{e}).gazeY       = data(qDat,9);
            % get deviation from center in deg for x and y
            datCm = [data(qDat,5) repmat([0 dist],sum(qDat),1)];
            refCm = repmat([0 0 dist],sum(qDat),1);
            ETdata.(tfield).(recordings{r}).(events{e}).dxDeg       = angleBetween(datCm,refCm).*sign(ETdata.(tfield).(recordings{r}).(events{e}).dxCm);
            datCm = [zeros(sum(qDat),1) data(qDat,6) repmat(dist,sum(qDat),1)];
            refCm = repmat([0 0 dist],sum(qDat),1);
            ETdata.(tfield).(recordings{r}).(events{e}).dyDeg       = angleBetween(datCm,refCm).*sign(ETdata.(tfield).(recordings{r}).(events{e}).dyCm);
            
            if contains(events{e},'validation')
                fname = sprintf('validationCodingAdjust_DN_%s_%s_%s.mat',trackers{t},recordings{r},events{e});
                if exist(fullfile(fixCodeDir,fname),'file')
                    fix = load(fullfile(fixCodeDir,fname),'fix'); fix = fix.fix;
                    if size(fix.fixMarks,1)==2*size(fix.fixPos,1)
                        fix.fixMarks(1:2:end,:) = [];
                    end
                    assert(sum(qDat)==size(fix.rawdat,1))
                    ETdata.(tfield).(recordings{r}).(events{e}).fix.marks  = fix.fixMarks;
                    ETdata.(tfield).(recordings{r}).(events{e}).fix.target = fix.target;
                else
                    % there is that one file that i couldn't possibly code
                    % because the recording during that interval is too
                    % crappy
                    assert(strcmp(fname,'validationCodingAdjust_DN_pupil-labs_pt2_validation2.mat'))
                    fprintf('file %s not found, skipping fix coding\n',fname);
                end
            end
        end
        
        % Store data to enable looking into data loss in the form of
        % missing video frames or repeated samples.
        iStart = min(coding{4}(qTrack & qRec));
        iEnd   = max(coding{5}(qTrack & qRec));
        qDat = data(:,1)>=iStart & data(:,1)<=iEnd;
        
        ETdata.(tfield).(recordings{r}).allTs       = data(qDat,7);
        ETdata.(tfield).(recordings{r}).allXY       = data(qDat,8:9);
        ETdata.(tfield).(recordings{r}).confidence  = data(qDat,3);
    end
end

save ETdata ETdata
