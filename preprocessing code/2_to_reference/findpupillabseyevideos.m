d='C:\dat\projects\glasses test\data\processed\pupil-labs';
f = FolderFromFolder(d);
fs = {f.name};

% build info about raw recordings
d2 = 'C:\dat\projects\glasses test\data\recordings\pupil-labs';
f2 = FolderFromFolder(d2);
lookup = {};
for p=1:length(f2)
    f22 = FolderFromFolder(fullfile(d2,f2(p).name));
    for q=1:length(f22)
        a = readtable(fullfile(d2,f2(p).name,f22(q).name,'user_info.csv'));
        b = table2array(a(1,2));
        lookup(end+1,:) = {b{1},fullfile(d2,f2(p).name,f22(q).name)};
    end
end

% now copy files

for p=1:size(lookup,1)
    assert(any(strcmp(lookup{p,1},fs)))
    % build paths
    dest = fullfile(d,lookup{p,1});
    src  = fullfile(lookup{p,2},'eye0.mp4');
    % copy file over
    copyfile(src,dest,'f')
    
    
    src  = fullfile(lookup{p,2},'eye0_timestamps.npy');
    % copy file over
    copyfile(src,dest,'f')
    
    
    src  = fullfile(lookup{p,2},'world_timestamps.npy');
    % copy file over
    copyfile(src,dest,'f')
end