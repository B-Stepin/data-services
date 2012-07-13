function radar_WERA_main(site_code, isQC)
%example of function call
%radar_WERA_main('SAG', false)
%
%The text file 'SAG_last_update.txt' contains the date of the last update on
%the first line of the file.
%

%see files acorn_summary_WERA.m and config.txt for any changes on the
%following global variables
global delayedModeStart
global delayedMode
global logfile 
global datadir

%new global variables are defined
global dfradialdata
global inputdir
global outputdir
global ncwmsdir
global dateFormat

nProcessedFiles = 0;

if isQC
    suffixConfigQC = 'QC';
    suffixUpdateQC = '_QC';
else
    suffixConfigQC = 'nonQC';
    suffixUpdateQC = '';
end

dfradialdata    = fullfile(readConfig('df.path'),   readConfig(['df.radWERA' suffixConfigQC '.subpath']));
inputdir        = fullfile(datadir,                 readConfig(['inputWERA' suffixConfigQC '.subpath']));
outputdir       = fullfile(inputdir,                readConfig(['outputWERA' suffixConfigQC '.subpath']));
ncwmsdir        = fullfile(readConfig('ncwms.path'),readConfig(['ncwmsWERA' suffixConfigQC '.subpath']));
dateFormat      = 'yyyymmddTHHMMSS';

%
%USE of the site_code input to find the corresponding radar station
switch site_code
    case {'GBR', 'CBG'}     % Capricorn Bunker Group Site (Queensland)
        station1 = 'TAN';   % Tannum Sands radar station
        station2 = 'LEI';   % Lady Elliott Island radar station
        filelastupdate = fullfile(inputdir, ['CBG' suffixUpdateQC '_last_update.txt']);
    case 'SAG'              % South Australia Gulf site (South Australia)
        station1 = 'CWI';   % Cape Wiles radar station
        station2 = 'CSP';   % Cape Spencer radar station
        filelastupdate = fullfile(inputdir, ['SAG' suffixUpdateQC '_last_update.txt']);
    case {'PCY', 'ROT'}     % Rottnest Shelf site (Western Australia)
        station1 = 'GUI';   % Guilderton radar station
        station2 = 'FRE';   % Fremantle radar station
        filelastupdate = fullfile(inputdir, ['ROT' suffixUpdateQC '_last_update.txt']);
    case {'COF'}            % Coffs Harbour Site (New South Wales)
        station1 = 'RRK';   % Red Rock radar station
        station2 = 'NNB';   % North Nambucca radar station
        filelastupdate = fullfile(inputdir, ['COF' suffixUpdateQC '_last_update.txt']);        
end

if delayedMode
    lastUpdate = delayedModeStart;
else
    %OPEN the text file and read the first line
    fid = fopen(filelastupdate, 'r');
    lastUpdate = fgetl(fid);
    fclose(fid);
end

[year, month, day, hour, ~, ~] = datevec(lastUpdate, dateFormat);
year    = num2str(year,     '%i');
month   = num2str(month,    '%02i');
day     = num2str(day,      '%02i');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Call the subfunction "getListFiles"
%the subfunction will return a list of NetCDF files available on the ARCS DAtafabric
%and ready for processing for a particular radar station
%the variables "listFilesStation1" and "listFilesStation2" are then created
%

fprintf('%-30s ..... ', 'Listing available radial files'); tic;

%STATION 1
gotListFilesStation1 = false;
try
    listFilesStation1 = getListFiles(year, month, day, hour, station1, true);
    if ~isempty(listFilesStation1), gotListFilesStation1 = true; end
catch e
    fid_w5 = fopen(logfile, 'a');
    fprintf(fid_w5, '%s %s %s %s :\r\n', datestr(clock), station1, ...
        ['Problem in ' func2str(@getListFiles) ...
        ' to access files for this station on the following date'], ...
        lastUpdate);
    fprintf(fid_w5, '%s\r\n', e.message);
    s = e.stack;
    for k=1:length(s)
        fprintf(fid_w5, '\t%s\t(%s: %i)\r\n', s(k).name, s(k).file, s(k).line);
    end
    fclose(fid_w5);
end

%STATION 2
gotListFilesStation2 = false;
try
    listFilesStation2 = getListFiles(year, month, day, hour, station2, true);
    if ~isempty(listFilesStation2), gotListFilesStation2 = true; end
catch e
    fid_w5 = fopen(logfile, 'a');
    fprintf(fid_w5, '%s %s %s %s :\r\n', datestr(clock), station1, ...
        ['Problem in ' func2str(@getListFiles) ...
        ' to access files for this station on the following date'], ...
        lastUpdate);
    fprintf(fid_w5, '%s\r\n', e.message);
    s = e.stack;
    for k=1:length(s)
        fprintf(fid_w5, '\t%s\t(%s: %i)\r\n', s(k).name, s(k).file, s(k).line);
    end
    fclose(fid_w5);
end


fprintf('%3.3f %s\n', toc, 'sec')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%TEST to check if data is available for the two radar stations
if (gotListFilesStation1 && gotListFilesStation2)
    
    tic;
    
    nFiles = max(length(listFilesStation1), length(listFilesStation2));
    
    while (length(listFilesStation1) < nFiles), listFilesStation1{end+1} = []; end
    while (length(listFilesStation2) < nFiles), listFilesStation2{end+1} = []; end
    
    filesTimeInterval   = 10; % in minutes
    averagingTimePeriod = 60; % in minutes
    nFilesPerAveragingTimePeriod = floor(averagingTimePeriod/filesTimeInterval);
    nAveragingTimePeriod = floor(nFiles/nFilesPerAveragingTimePeriod);
    
    for i = 1:nAveragingTimePeriod
        % we store the 2 stations filename in the same variable
        namefile = cell(nFilesPerAveragingTimePeriod*2, 1);
        k = 1;
        for j = 1:nFilesPerAveragingTimePeriod
            namefile{k} = listFilesStation1{j + nFilesPerAveragingTimePeriod*(i-1)};
            k = k + 1;
            namefile{k} = listFilesStation2{j + nFilesPerAveragingTimePeriod*(i-1)};
            k = k + 1;
        end
        
        nEmptyStation1 = sum(strcmpi(listFilesStation1(nFilesPerAveragingTimePeriod*(i-1)+1:nFilesPerAveragingTimePeriod*i), ''));
        nEmptyStation2 = sum(strcmpi(listFilesStation2(nFilesPerAveragingTimePeriod*(i-1)+1:nFilesPerAveragingTimePeriod*i), ''));
        
        if (nEmptyStation1 <= nFilesPerAveragingTimePeriod/2) && ...
                (nEmptyStation2 <= nFilesPerAveragingTimePeriod/2)
            %Call the subfunction "radar_WERA_create_current_data"
            %the subfunction will open the NetCDF files and process the data in order
            %to create a new NetCDF file (1 hour averaged product)
            try
                toto = radar_WERA_create_current_data(namefile, site_code, isQC);
                disp(toto);
                nProcessedFiles = nProcessedFiles + 1;
                
                if ~delayedMode
                    %The date included in the input file is then updated
                    fid_w4 = fopen(filelastupdate, 'w');
                    fprintf(fid_w4, '%s\r\n', toto);
                    fclose(fid_w4);
                end
            catch e
                fid_w5 = fopen(logfile, 'a');
                fprintf(fid_w5, '%s %s %s\r\n', datestr(clock), ...
                    ['Problem in ' func2str(@radar_WERA_create_current_data) ' to process the following files'], ...
                    [namefile{1} ' to ' namefile{12}]);
                fprintf(fid_w5, '%s\r\n', e.message);
                s = e.stack;
                for k=1:length(s)
                    fprintf(fid_w5, '\t%s\t(%s: %i)\r\n', s(k).name, s(k).file, s(k).line);
                end
                fclose(fid_w5);
            end
        end
    end
    fprintf('%-30s ..... ', ['Done : ' num2str(nProcessedFiles) ' files']);
    fprintf('%3.3f %s\n', toc, 'sec')
else
    disp('No files to process');
    fid_w5 = fopen(logfile, 'a');
    fprintf(fid_w5, '%s %s %s %s\r\n', datestr(clock), site_code, ...
        'Problem : NO FILES TO PROCESS', lastUpdate);
    fclose(fid_w5);
end

end