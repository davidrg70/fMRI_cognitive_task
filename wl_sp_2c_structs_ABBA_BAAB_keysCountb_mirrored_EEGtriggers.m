% 1-1 ABAB ABAB BABA BABA
% 1-2 BABA BABA ABAB ABAB

clc;
clear all;
close all;
rng('shuffle');
SendSignal(0) % EEG trigger

% just the initial values of variables
VOWEL = 1;
FRACTAL = 2;
GREENRight = 1;
GREENLeft = 2;

prompt = {'Outputfile', 'Subject''s number:', 'age', 'gender', 'group', 'FirstCondition (VOWEL(1)/FRACTAL(2))', 'KEY Counterbalancing (GreenR(1)/RedR(2))'};
defaults = {'Subject_', '1', '18', 'F', 'control', '_', '_'};
answer = inputdlg(prompt, 'NumberExp1', 2, defaults);
[output, subid, subage, gender, group, startCondition, keyCounterbalancing] = deal(answer{:}); % all input variables are strings

% Switch for conditions counterbalancing
switch startCondition
    case {'1', 'VOWEL'}
        useCondition = [VOWEL];
    case {'2', 'FRACTAL'}
        useCondition = [FRACTAL];
    otherwise
        error('unknown Condition')
end

% Switch for keys counterbalancing
switch keyCounterbalancing
    case {'1', 'Green-right'}
        keyCounterbalancing = [GREENRight];
        GREENRight = 1;
        GREENLeft = 0;
    case {'2', 'Green-left'}
        keyCounterbalancing = [GREENLeft];
        GREENRight = 0;
        GREENLeft = 1;
    otherwise
        error('unknown Counterbalancing')
end

global logfile

% Screen and Keyboard parameters
screenNumber = 1; % monitor/screen to use
SetupScanner = true;

KbName('UnifyKeyNames');
spaceKey = KbName('space'); escKey = KbName('ESCAPE');

%%%%%%% Section that is part of Scanner-triggers
keylist = zeros(1,256);
if SetupScanner && GREENRight == 1
    Key1=KbName('1!'); % RED
    Key2=KbName('2@'); % GREEN
    scannerKey = (KbName('9('));  % evaluates to 57: fORP pinkie left hand or keyboard 9 from numbers above letters or SCANNERTRIGGER
    keylist([spaceKey, escKey, Key1, Key2, scannerKey]) = 1;
elseif SetupScanner && GREENLeft == 1
    Key1=KbName('2@'); % RED
    Key2=KbName('1!'); % GREEN
    scannerKey = (KbName('9('));  % evaluates to 57: fORP pinkie left hand or keyboard 9 from numbers above letters or SCANNERTRIGGER
    keylist([spaceKey, escKey, Key1, Key2, scannerKey]) = 1;
end

keylist(spaceKey) = 1;
keylist(escKey) = 1;
% create and start a restricted KbQueue
KbQueueCreate(-1, keylist); %'-1' uses default keyboard
KbQueueStart;
HideCursor();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

gray = [200 200 200]; white = [255 255 255]; black = [0 0 0]; turquoise = [204 255 204];
bgcolor = white; textcolor = black; fontsize = 60; change_screen = turquoise;
timestamp=datestr(now,'yyyymmdd-HHMMss');
outputname = [timestamp '-' output gender subid group subage];
folder='experiments/';

outfile = fopen([folder 'wl_self_paced_results' datestr(now,'yyyy-mm-dd-HH-MM-SS') '.txt'], 'w'); % open a file for writing data out
logfile = fopen([folder 'wl_self_paced_logfile' datestr(now,'yyyy-mm-dd-HH-MM-SS') '.log'], 'w'); % open a file for writing data out
fprintf(outfile, 'imagesDir\timage_shown.name\tAccuracy\tReaction_time\timage_shown\tAccumulated_time\t\n'); % column titles in printed txt
writelog(['Date: ' datestr(now,'yyyy-mm-dd-HH-MM-SS')]);

num_blocks = [8 8]; %number of blocks (must be evens)
num_items = [6 6]; %number of items in every block (must be evens)
calification = [24 24]; % numbers that allow to judge if the answer is correct or not (these refer to the HALF of files in the folders: the half are correct, the other half are incorrect)

%% Images Directories & Instructions for every section

images_directories = {'mixed_images', 'mixed_fractals'};
randomized_images = randperm(num_blocks(useCondition)* num_items(useCondition));
images = reshape([randomized_images], num_blocks(useCondition), num_items(useCondition));

% Guide circles (with colors)
Screen('Preference', 'SkipSyncTests', 1);

% Using PsychImaging to flip the image horizontally for Optostim monitor
flipHorizontally = true;
if flipHorizontally
    PsychImaging('PrepareConfiguration');
    PsychImaging('AddTask', 'AllViews', 'FlipHorizontal');
end

[window, screenrect] = PsychImaging( 'OpenWindow',screenNumber);
center = [screenrect(3)/2 screenrect(4)/2];

buttonSize=150;
button1=[0.1*screenrect(3)-0.5*buttonSize screenrect(4)-0.1*screenrect(4)-0.5*buttonSize 0.1*screenrect(3)+0.5*buttonSize screenrect(4)-0.1*screenrect(4)+0.5*buttonSize]';
button2=[screenrect(3)-0.1*screenrect(3)-0.5*buttonSize screenrect(4)-0.1*screenrect(4)-0.5*buttonSize screenrect(3)-0.1*screenrect(3)+0.5*buttonSize screenrect(4)-0.1*screenrect(4)+0.5*buttonSize]';
oval_color1 = [255 0 0]; oval_color2 = [0 255 0];

HideCursor();

% Instructions
    switch useCondition
        case VOWEL && GREENRight == 1
            Screen('FillRect', window,bgcolor); Screen('TextSize', window, 24); 
            Screen('FillOval', window, oval_color1, button1); 
            Screen('FillOval', window, oval_color2, button2);
            DrawFormattedText(window, 'Grün: i ist im Wort oder das kleines Bild ist im großem Bild', 'center', center(2), textcolor);
            DrawFormattedText(window, 'Rot: i ist NICHT im Wort oder das kleines Bild ist NICHT im großem Bild', 'center', center(2) + 40, textcolor);
            
        case FRACTAL && GREENRight == 1
            Screen('FillRect', window,bgcolor); Screen('TextSize', window, 24); 
            Screen('FillOval', window, oval_color1, button1); 
            Screen('FillOval', window, oval_color2, button2);
            DrawFormattedText(window, 'Grün: das kleines Bild ist im großem Bild oder i ist im Wort', 'center', center(2), textcolor);
            DrawFormattedText(window, 'Rot: das kleines Bild ist NICHT im großem Bild oder i ist NICHT im Wort', 'center', center(2) + 40, textcolor);
        
        case VOWEL && GREENLeft == 1
            Screen('FillRect', window,bgcolor); Screen('TextSize', window, 24); 
            Screen('FillOval', window, oval_color2, button1); 
            Screen('FillOval', window, oval_color1, button2);
            DrawFormattedText(window, 'Grün: i ist im Wort oder das kleines Bild ist im großem Bild', 'center', center(2), textcolor);
            DrawFormattedText(window, 'Rot: i ist NICHT im Wort oder das kleines Bild ist NICHT im großem Bild', 'center', center(2) + 40, textcolor);
            
        case FRACTAL && GREENLeft == 1
            Screen('FillRect', window,bgcolor); Screen('TextSize', window, 24); 
            Screen('FillOval', window, oval_color2, button1); 
            Screen('FillOval', window, oval_color1, button2);
            DrawFormattedText(window, 'Grün: i ist im Wort oder das kleines Bild ist im großem Bild', 'center', center(2), textcolor);
            DrawFormattedText(window, 'Rot: i ist NICHT im Wort oder das kleines Bild ist NICHT im großem Bild', 'center', center(2) + 40, textcolor);
    end
    Screen('Flip',window );
    WaitSecs(8);

%% Scanner triggers!

% create and start a restricted KbQueue
KbQueueCreate(-1, keylist); %'-1' uses default keyboard
KbQueueStart;

if SetupScanner
    DrawFormattedText(window, 'Warte auf Scanner ...','center','center', textcolor);
    Screen('Flip',window );
    writelog('SHOW Title screen');
    HideCursor();
    
    ExperimentIsStarted = false;
    % get data between KbQueueStart and KbQueueCheck or between KbQueueCheck
    [pressed, firstPress, firstRelease, lastPress, lastRelease] = KbQueueCheck;
    while ~ExperimentIsStarted
        [pressed, firstPress, firstRelease, lastPress, lastRelease] = KbQueueCheck;
        if pressed
            if firstPress(scannerKey) > 0
                ExperimentIsStarted = true;
                ScannerStartTime = firstPress(scannerKey); % record ScannerStartTime from KbQueue
                stopwatch(ScannerStartTime); % stopwatch variable indexes the ScannerStartTime variable
                writelog(sprintf('ScannerStarTime: %f', ScannerStartTime));
            elseif firstPress(escKey) > 0
                ShowCursor;
                fclose(outfile);
                fclose(logfile);
                Screen('CloseAll');
                return;
            end
        end
    end
else
    ExperimentIsStarted = false;
    [pressed, firstPress, firstRelease, lastPress, lastRelease] = KbQueueCheck;
    while ~ExperimentIsStarted
        % get data between KbQueueStart and KbQueueCheck or between KbQueueCheck
        [pressed, firstPress, firstRelease, lastPress, lastRelease] = KbQueueCheck;
        if pressed
            if firstPress(spaceKey) > 0
                ExperimentIsStarted = true;
                writelog('Experiment started with SPACE');
            elseif firstPress(escKey) > 0
                ShowCursor;
                fclose(outfile);
                fclose(logfile);
                Screen('CloseAll');
                return;
            end
        end
    end
end

for iBlock=1:num_blocks(useCondition)
    for iDir = 1:2
        % switches of which condition to show next
% 1) if useCondition 2: select Dir according to the condition initially selected (BUT IT WILL SWITCH THE CONDITIONS EVERY TIME THAT iDIR LOOP ITERATES)
        if useCondition == 1
            useDir = iDir;
        else %useCondition == 2
            useDir = 3 - iDir; %(3-iDir) maps iDir [1 2] onto [3-1 3-2] i.e. [2 1], this is how the order of the conditions is reversed
        end
        
% 2) if the script is in the second half of the task: switch conditions (ALTERNANCY)
        if iBlock <= num_blocks(useCondition)/2 % IF BLOCKS ARE 1-4 USE DIR2, BUT IF BLOCKS ARE 5-8 USE DIR1 (ALTERNANCY)
            iDirectory = useDir; % iDirectory is index (as the for-loop iterates, the index makes the content of several variables to change)
        else
            iDirectory = (3-useDir); %(3-useDir) maps useDir [1 2] onto [3-1 3-2] i.e. [2 1], that is the order of the conditions is reversed in the second half of the experiment
        end
        
        imagesDir = char(images_directories(iDirectory));
        imagesFiles = dir(imagesDir);
        imagesFiles = imagesFiles(3:size(imagesFiles,1));
       
        %% Loops
        
        % BEGINNING-CHANGE OF SCREEN
        % Fixation cross (Inter-stimuli)
        HideCursor();
        
        % Guide circles (with colors)
        buttonSize=150;
        button1=[0.1*screenrect(3)-0.5*buttonSize screenrect(4)-0.1*screenrect(4)-0.5*buttonSize 0.1*screenrect(3)+0.5*buttonSize screenrect(4)-0.1*screenrect(4)+0.5*buttonSize]';
        button2=[screenrect(3)-0.1*screenrect(3)-0.5*buttonSize screenrect(4)-0.1*screenrect(4)-0.5*buttonSize screenrect(3)-0.1*screenrect(3)+0.5*buttonSize screenrect(4)-0.1*screenrect(4)+0.5*buttonSize]';
        oval_color1 = [255 0 0]; oval_color2 = [0 255 0];
        
        for iItem=[1:num_items(useCondition)]% + num_items(useCondition)*(iBlock-1)
            
            % Fixation cross (Inter-stimuli)
            Screen('FillRect', window, bgcolor); 
            Screen('TextSize', window, fontsize*2); 
            Screen('DrawLine', window, textcolor, center(1)-20, center(2), center(1)+20, center(2),3); 
            Screen('DrawLine', window, textcolor, center(1), center(2)-20, center(1), center(2)+20,3); 
            Screen('Flip', window); 
            WaitSecs(1);
            
            image_shown = images(iBlock, iItem);
            if GREENRight == 1
                Screen('FillRect', window, bgcolor);
                image_data = imread(fullfile(imagesDir, imagesFiles(image_shown).name));
                texture_index = Screen('MakeTexture', window, image_data);
                Screen('DrawTexture', window, texture_index, [], []);
                Screen('FillOval', window, oval_color1, button1); 
                Screen('FillOval', window, oval_color2, button2);
                SendSignal(3)
                Screen('Flip',window);
            elseif GREENLeft == 1
                Screen('FillRect', window, bgcolor);
                image_data = imread(fullfile(imagesDir, imagesFiles(image_shown).name));
                texture_index = Screen('MakeTexture', window, image_data);
                Screen('DrawTexture', window, texture_index, [], []);
                Screen('FillOval', window, oval_color2, button1);
                Screen('FillOval', window, oval_color1, button2);
                SendSignal(3)
                Screen('Flip',window);
            end
            
            % RECORD RESPONSE
            timeStart = GetSecs;
            [pressed, firstPress, firstRelease, lastPress, lastRelease] = KbQueueCheck;
            keyIsDown = 0;
            correct = 1;
            rt = 0;
            keypressed = -1;
            
            if keyIsDown
                while 1
                    if ~keyIsDown
                        break;
                    end
                end
            end
            while 1
            [pressed, firstPress, firstRelease, lastPress, lastRelease] = KbQueueCheck;
                if pressed && ~keyIsDown
                    keyIsDown = 1;
                    nKeys = sum(firstPress>0);
                        if firstPress(Key1)>0 || firstPress(Key2)>0
                            keypressed = find(firstPress);
                            SendSignal(4)
                            rt = (firstPress(keypressed) - timeStart);
                            at = (firstPress(keypressed) - ScannerStartTime);
                            Screen('Flip', window);
                            break;
                        elseif firstPress(escKey)
                            ShowCursor;
                            fclose(outfile);
                            Screen('CloseAll');
                            return
                        end
                        keyIsDown = 0;
                        firstPress = 0;
                end
            end
            
            if GREENRight == 1
                if keypressed(1) == Key1 && image_shown > calification(useCondition) % Key1 is left arrow for Letter NOT part of the Word ('Incorrect' images), the keypressed(1) is to take just the fisrt value of the variable keypressed and avoid coincident pressure of one key + trigger (and consequent error during scanning)
                    writelog(sprintf('Correct %.3f', rt));
                    correct = 1;
                elseif keypressed(1) == Key2 && image_shown <= calification(useCondition) % Key 2 is right arrow Corresponding Letter to Word ('Correct' images), the keypressed(1) is to take just the first value of the variable keypressed and avoid coincident pressure of one key + trigger (and consequent error during scanning)
                    writelog(sprintf('Correct %.3f', rt));
                    correct = 1;
                else
                    writelog(sprintf('Incorrect %.3f', rt));
                    correct = 0;
                end
            elseif GREENLeft == 1
                if keypressed(1) == Key1 && image_shown > calification(useCondition) % Key 1 function inverted
                    writelog(sprintf('Correct %.3f', rt));
                    correct = 1;
                elseif keypressed(1) == Key2 && image_shown <= calification(useCondition) % Key 2 function inverted
                    writelog(sprintf('Correct %.3f', rt));
                    correct = 1;
                else
                    writelog(sprintf('Incorrect %.3f', rt));
                    correct = 0;
                end
            end
            
            % PRINTS A .TXT FILE WITH ALL EXPERIMENT DATA
            fprintf(outfile,'%s\t %s\t %d\t %.3f\t %d\t %.3f\t\n', imagesDir, imagesFiles(image_shown).name, correct, rt, image_shown, at);
            
            % PRINTS EXPERIMENT DATA IN COMMAND WINDOW
            writelog(strcat('KEY Keycode ',KbName(keypressed),' Correct ',num2str(correct),' Reaction time ', num2str(rt), ' Accumulated time', num2str(at))); % Accumulated time is time since scanner start
            
            % STRUCTURES TO COLLECT BEHAVIORAL DATA (DATA IS NOT SAVED WITH THE SAME SUBJECT´S REAL SEQUENCE) - it didn´t work neither with {(iItem, iBlock, iDir)}
            imagesDirectory{iItem, iBlock} = imagesDir;
            results.imagesDirectory = imagesDirectory;
            
            imageName{iItem, iBlock} = imagesFiles(image_shown).name;
            results.imageFileName = imageName;
            
            accuracy(iItem, iBlock) = correct;          % the 'accuracy' variable takes the iteration of the 'i' indices to fill the structure - No matter the order, the "box" is filled in every "dimension" applied to it
            results.accuracy = accuracy;
            
            reaction_time(iItem, iBlock) = rt;          % the 'reaction_time' variable takes the iteration of the 'i' indices to fill the structure - No matter the order, the "box" is filled in every "dimension" applied to it
            results.reaction_time = reaction_time;
            
            accumulated_time(iItem, iBlock) = at;       %  the 'accumulated_time' variable takes the iteration of the 'i' indices to fill the structure
            results.accumulated_time = accumulated_time;
            
            save('C:\Projekte\fMRI-children-Rolandic\working-language\experiments\results', 'accuracy', 'reaction_time', 'accumulated_time'); % save results of structures into .mat file
            % save('C:\toolbox\working-language\experiments\results', 'accuracy', 'reaction_time', 'accumulated_time'); % save results of structures into .mat file
 
        end % end of iItem for-loop
    end %end of iDir for-loop
end % end of images_directories for-loop

Screen('CloseAll');
fclose(outfile);
fclose(logfile);

%% Functions
function writelog(out)
global logfile
persistent lasttime
if isempty(lasttime)
    lasttime = GetSecs();
end
elapsedtime = GetSecs()-lasttime;
lasttime = GetSecs();
outstring = sprintf('%s - %.3f : %s\n',datestr(now,'HH:MM:ss.FFF'),elapsedtime,out);
fprintf(logfile, '%s',outstring);
fprintf('%s',outstring);
end

function time = stopwatch(code)
persistent lasttime % persistent variable that allows to keep its values constant (last lap)
persistent starttime
if isempty(code)
    starttime = GetSecs();
    lasttime = starttime;
    return
end

if code == 1    %% runtime1
    time = GetSecs()- starttime; % current time minus starttime (since Stopwatch was reset or started)
elseif code == 2 %% lap time
    time = GetSecs()- lasttime; % time since the last lap or time since last reset (if it has never been called)
    lasttime = GetSecs();
elseif code>2 %% set start time externally, assuming it is never below 2
    starttime = code;
    lasttime = starttime;
end
end


% EEG triggers (send signal from main pc to pc recording EEG, to mark time-points)
function SendSignal(onof)
 
    ioObj = io64;
    %status = io32(ioObj);
    address = hex2dec('D050');%standard LPT1 output port address
    status = io64(ioObj);
    io64(ioObj, address, onof);
    
end