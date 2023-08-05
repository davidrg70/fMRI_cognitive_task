% Created by David Garnica, david.garnica@med.uni-goettingen.de
% 2020, Universitätsmedizin Göttingen, Neurology Department

% Version 1.3 JUST ENCODING AND RETRIEVAL

% Experimental parameters
clearvars
global logfile
SendSignal(0)
%Screen('Preference', 'SkipSyncTests', 1);
screenNumber = 1; %max(Screen('Screens')); % monitor/screen to use
SetupScanner = true;

interTrialInterval = [2 2.5 3];
nTrialsPerBlock = 20; % should be even
tasks=[1 1 1];
blocks = 1; % expected to have the same number of blocks for each condition, otherwise untested, max 2 repetitions per block type
              % 10 * 2 = 20 trials (10 in every block) - that means 60 trials in encoding and 20 in retrieval
set = ones(1,max(blocks));
letters = 'BCDFGHKLMNPRSTW';
encodedLetters = 3;
time_of_letter = 2; % seconds per every letter
delaytime = 3;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Login prompt and open file for writing data out

prompt = {'Outputfile', 'Subject''s number:', 'age', 'gender', 'group', 'KEY Counterbalancing (GreenR(1)/RedR(2))'};
defaults = {'WM_2C_', '1', '10', 'F', 'control', '_'};
answer = inputdlg(prompt, 'NumberExp1', 2, defaults);
[output, subid, subage, gender, group, keyCounterbalancing] = deal(answer{:}); % all input variables are strings
timestamp=datestr(now,'yyyymmdd-HHMMss');
outputname = [timestamp '-' output gender subid group subage];
folder='experiments/';
outfile = fopen([folder outputname '.txt'], 'w'); % open a file for writing data out
logfile = fopen([folder outputname '.log'], 'w'); % open a file for writing data out

fprintf(outfile, 'subid\tsubage\tgender\tgroup\tblockNumber\ttrialNumber\tpresentation\tis_correct\tkeypressed\taccuracy\tReactionTime\tAccumulatedTimeResponse\tAccumulatedTimeEncoding1\tAccumulatedTimeEncoding2\tAccumulatedTimeEncoding3\tAccumulatedTimeRetrieval\t\n');

writelog(['Date: ' datestr(now,'yyyy-mm-dd')]);
% import_list();

% just the initial values of variables
GREENRight = 1;
GREENLeft = 2;

% Switch for keys Counterbalancing
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

KbName('UnifyKeyNames');
spaceKey = KbName('space');
escKey = KbName('ESCAPE');

% to buttons for fMRI
keylist = zeros(1,256);
if SetupScanner && GREENRight == 1
    Key1=KbName('1!'); %correct
    Key2=KbName('2@'); %false
    scannerKey = (KbName('9('));  % evaluates to 57: fORP pinkie left hand or keyboard 9 from numbers above letters or SCANNERTRIGGER
    keylist([spaceKey, escKey, Key1, Key2, scannerKey]) = 1;
elseif SetupScanner && GREENLeft == 1
    Key1=KbName('2@'); % correct
    Key2=KbName('1!'); % false
    scannerKey = (KbName('9('));  % evaluates to 57: fORP pinkie left hand or keyboard 9 from numbers above letters or SCANNERTRIGGER
    keylist([spaceKey, escKey, Key1, Key2, scannerKey]) = 1;
end

keylist(spaceKey) = 1;      % corrkey1 = 37; % left arrow
keylist(escKey) = 1;        % corrkey2 = 39; % right arrow
gray = [200 200 200]; white = [255 255 255]; black = [0 0 0];
bgcolor = gray;
textcolor = black;
fontsize = 60;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Randomization
writelog('START Randomization');
rng('shuffle');

%% encoded letter
i_letter = zeros(1,length(letters)); % indices of the letter in the letter string
for i = 1:length(letters)
    i_letter(i) =  i;
end

letterStash=[]; % storing letters that have been picked

for i = 1:2 % set
    for j = 1:nTrialsPerBlock % trial
        i_letter = Shuffle(i_letter);
        letterBlockSets(1,i,j,:) = i_letter(1:encodedLetters); % letters to encode, indices: 1=task, 2=task, 3=trial, 4=letter indices
        letterStash = [letterStash i_letter(1:encodedLetters)];
    end
end

tries = 0;
maxtries = 1000;
while tries<maxtries
    tries = tries+1;
    letterStash = Shuffle(letterStash);
    duplicate = false;
    for i = 1:2*nTrialsPerBlock
        testEncoding = letterStash(1+(i-1)*encodedLetters:(i-1)*encodedLetters+encodedLetters);
        if numel(testEncoding) ~= numel(unique(testEncoding))
            duplicate = true;
            break
        end
    end
    if duplicate == false
        break
    end
end

for i = 1:2
    for j = 1:nTrialsPerBlock
        letterBlockSets(2,i,j,:) = letterStash(1:encodedLetters);
        letterStash = letterStash(encodedLetters+1:length(letterStash));
    end
end

% random letters for baseline
i=1; % set
while i<3
    for j = 1:nTrialsPerBlock %trial
        i_letter = Shuffle(i_letter);
        letterBlockSetsBaseline(i,j) = i_letter(1);
    end
    if length(unique(letterBlockSetsBaseline(i,:)))>1
        i=i+1;
    else
        writelog('INFO All letters for baseline task identical. re-rolled letters');
    end
end
% When to shuffle letters in retrieval
for i = 1:max(blocks)
    for j = 1:2
        shuffleEncodedLetters(i,j,:) = Shuffle([ones(1,nTrialsPerBlock/2) zeros(1,nTrialsPerBlock/2)]);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  Screen parameters
% Using PsychImaging to flip the image horizontally for Optostim monitor
flipHorizontally = true;
if flipHorizontally
    PsychImaging('PrepareConfiguration');
    PsychImaging('AddTask', 'AllViews', 'FlipHorizontal');
end

[mainwin, screenrect] = PsychImaging( 'OpenWindow',screenNumber);
center = [screenrect(3)/2 screenrect(4)/2];

HideCursor();
buttonSize = 150;
button = [0.1*screenrect(3)-0.5*buttonSize screenrect(4)-0.1*screenrect(4)-0.5*buttonSize 0.1*screenrect(3)+0.5*buttonSize screenrect(4)-0.1*screenrect(4)+0.5*buttonSize;screenrect(3)-0.1*screenrect(3)-0.5*buttonSize screenrect(4)-0.1*screenrect(4)-0.5*buttonSize screenrect(3)-0.1*screenrect(3)+0.5*buttonSize screenrect(4)-0.1*screenrect(4)+0.5*buttonSize]';
buttonColor = [255 0 0; 0 255 0]';
invertedbuttonColor = [0 255 0; 255 0 0]';

% create and start a restricted KbQueue
KbQueueCreate(-1, keylist); %'-1' uses default keyboard
KbQueueStart;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Experimental instructions, wait for Scanner trigger to start

if SetupScanner
    Screen('FillRect', mainwin ,bgcolor);
    Screen('TextSize', mainwin, 24);
    DrawFormattedText(mainwin, 'Warte auf Scanner ...','center','center', textcolor);
    Screen('Flip',mainwin );
    writelog('SHOW Title screen');

    ExperimentIsStarted = false;
    % get data between KbQueueStart and KbQueueCheck or between KbQueueCheck
    [pressed, firstPress, firstRelease, lastPress, lastRelease] = KbQueueCheck;
    while ~ExperimentIsStarted
        % get data between KbQueueStart and KbQueueCheck or between KbQueueCheck
        [pressed, firstPress, firstRelease, lastPress, lastRelease] = KbQueueCheck;
        if pressed
            if firstPress(scannerKey) > 0
                ExperimentIsStarted = true;
                ScannerStartTime = firstPress(scannerKey); % record ScannerStartTime from KbQueue
                stopwatch(ScannerStartTime); % stopwatch variable indexes the ScannerStartTime variable
                writelog(sprintf('ScannerStartTime: %f', ScannerStartTime));
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

%% Block loop
for block = 1:length(blocks)
    
    if GREENRight == 1
            Screen('FillRect', mainwin, bgcolor);
            Screen('TextSize', mainwin, 24);
            instructions = 'ROTE TASTE für falsche Position wie vorher, GRÜNE TASTE für gleiche Position wie vorher\n';
            DrawFormattedText(mainwin, instructions,'center','center', textcolor);
            Screen('FillOval', mainwin ,buttonColor ,button);
            Screen('Flip', mainwin);
            writelog('SHOW Instructions');
            WaitSecs(6);
    elseif GREENLeft == 1
            Screen('FillRect', mainwin, bgcolor);
            Screen('TextSize', mainwin, 24);
            instructions = 'GRÜNE TASTE für gleiche Position wie vorher, ROTE TASTE für falsche Position wie vorher\n';
            DrawFormattedText(mainwin, instructions,'center','center', textcolor);
            Screen('FillOval', mainwin ,invertedbuttonColor ,button);
            Screen('Flip', mainwin);
            writelog('SHOW Instructions');
            WaitSecs(6);
    end
    % trial loop
    for trial = 1:nTrialsPerBlock
        
        %% Encoding
        if blocks(block)<3
            shownLetters = squeeze(letterBlockSets(blocks(block),set(blocks(block)),trial,:));
        else
            shownLetters = letterBlockSetsBaseline(set(blocks(block)),trial);
        end
        for i = 1:length(shownLetters)
            
            Screen('FillRect', mainwin, bgcolor);
            Screen('TextSize', mainwin, fontsize*2);
            DrawFormattedText(mainwin, letters(shownLetters(i)),'center','center', textcolor);
            SendSignal(3)
            encoded = Screen('Flip', mainwin);
            atEnc(i) = (encoded - ScannerStartTime); % accumulated time at Encoding uses the time in which the screen flips / changes
            writelog(strcat('SHOW Block ', num2str(block),' Trial ', num2str(trial),' Letter ', letters(shownLetters(i)), ' AccTime ', num2str(atEnc(i))));
             
            WaitSecs(time_of_letter/2);
            SendSignal(0)
            WaitSecs(time_of_letter/2);  

        end
        
        %% task
        for task = 1:tasks(blocks(block))
            Screen('FillRect', mainwin, bgcolor);
            Screen('FillOval', mainwin ,buttonColor ,button);
            switch blocks(block)
                case 1
                    % fixation cross - delay
                    Screen('FillRect', mainwin, bgcolor); 
                    Screen('TextSize', mainwin, fontsize*2); 
                    Screen('DrawLine', mainwin, textcolor, center(1)-50, center(2), center(1)+50, center(2) ,3); 
                    Screen('DrawLine', mainwin, textcolor, center(1), center(2)-50, center(1), center(2)+50 ,3);
                    Screen('Flip', mainwin); writelog('DELAY - Fixation cross');
                    WaitSecs(delaytime);
                case 2
                    % fixation cross - delay
                    Screen('FillRect', mainwin, bgcolor); 
                    Screen('TextSize', mainwin, fontsize*2); 
                    Screen('DrawLine', mainwin, textcolor, center(1)-50, center(2), center(1)+50, center(2) ,3); 
                    Screen('DrawLine', mainwin, textcolor, center(1), center(2)-50, center(1), center(2)+50 ,3);
                    Screen('Flip', mainwin); writelog('DELAY - Fixation cross');
                    WaitSecs(delaytime);
            end
        end % task loop
        
        %% Retrieval
        retrievalStr = '';
        if blocks(block)<3
            revealedLetter = randi(length(shownLetters));
            if shuffleEncodedLetters(blocks(block),set(blocks(block)),trial) == 0
                is_correct = 1;
                for i = 1:length(shownLetters)
                    if i == revealedLetter
                        retrievalStr = [retrievalStr letters(shownLetters(i)) '  '];
                    else
                        retrievalStr = [retrievalStr '?  '];
                    end
                end
                retrievalStr = deblank(retrievalStr);
            else
                is_correct = 0;
                letterPositions = randperm(encodedLetters);
                letterPositions(letterPositions == revealedLetter) = [];
                for i = 1:length(shownLetters)
                    if i == letterPositions(1)
                        retrievalStr = [retrievalStr letters(shownLetters(revealedLetter)) '  '];
                    else
                        retrievalStr = [retrievalStr '?  '];
                    end
                end
                retrievalStr = deblank(retrievalStr);
            end
        else
            
            if shuffleEncodedLetters(blocks(block),set(blocks(block)),trial) == 0
                is_correct = 1;
                retrievalStr = letters(letterBlockSetsBaseline(set(blocks(block)),trial));
            else
                is_correct = 0;
                wrongLetters = letterBlockSetsBaseline(set(blocks(block)),:);
                wrongLetters(wrongLetters == letterBlockSetsBaseline(set(blocks(block)),trial)) = [];
                wrongLetters = Shuffle(wrongLetters);
                retrievalStr = letters(wrongLetters(1));
            end
            
        end
        presentedItem = retrievalStr;
        
        if GREENRight == 1
            Screen('FillRect', mainwin, bgcolor);
            Screen('FillOval', mainwin ,buttonColor ,button);
            Screen('TextSize', mainwin, fontsize*2);
            DrawFormattedText(mainwin, presentedItem,'center','center', textcolor);
             SendSignal(4)
            retrieved = Screen('Flip', mainwin);
            atRet = (retrieved - ScannerStartTime); % accumulated time at Retrieval uses the time in which the screen flips / changes
        elseif GREENLeft == 1
            Screen('FillRect', mainwin, bgcolor);
            Screen('FillOval', mainwin ,invertedbuttonColor ,button);
            Screen('TextSize', mainwin, fontsize*2);
            DrawFormattedText(mainwin, presentedItem,'center','center', textcolor);
            SendSignal(4)
            retrieved = Screen('Flip', mainwin);
            atRet = (retrieved - ScannerStartTime); % accumulated time at Retrieval uses the time in which the screen flips / changes
        end
        
        
        %% Pressed keys record
        timeStart = GetSecs();
        % empty KbQueueCheck
        [pressed, firstPress, firstRelease, lastPress, lastRelease] = KbQueueCheck;
        keyIsDown = 0;
        correct = 1;
        rt = 0;
        keypressed = -1;
        nResponses = 0;
        keyLastDown = false;
        while GetSecs()-timeStart <= 3
            [pressed, firstPress, firstRelease, lastPress, lastRelease] = KbQueueCheck;

            if pressed && ~keyLastDown
                keyLastDown = true;
                nKeys = sum(firstPress>0);
                if nKeys == 1
                    if firstPress(Key1)>0 || firstPress(Key2)>0
                        nResponses = nResponses + 1;                    % nResponses acts as a COUNTER, so later an If takes just the 2st response and prints the relevant data
                        keypressed = find(firstPress);
                        SendSignal(5)
                        rt = (firstPress(keypressed) - timeStart);
                        atResp = (firstPress(keypressed) - ScannerStartTime); % accumulated time at Response, uses the time in which the key is pressed instead
                        
                        if GREENRight == 1 % if Green-right side is for correct answer (Counterbalancing)
                            if keypressed == Key1 || keypressed == Key2
                                if ~is_correct && keypressed == Key1 || is_correct && keypressed == Key2
                                    correct = 1;
                                else
                                    correct = 0;
                                end
                            else
                                correct = 0;
                            end
                        elseif GREENLeft == 1 % if Green-left side is for correct answer (Counterbalancing)
                            if keypressed == Key1 || keypressed == Key2
                                if ~is_correct && keypressed == Key1 || is_correct && keypressed == Key2 % logic of answer inverted
                                    correct = 1;
                                else
                                    correct = 0;
                                end
                            else
                                correct = 0;
                            end
                        end
                        
                        % PRINTS A .TXT FILE WITH ALL EXPERIMENT DATA
                        if nResponses == 1                              % IF a 1st response is given, then the data will be printed in the txt
                            fprintf(outfile,'%s\t %s\t %s\t %s\t %d\t %d\t %s\t %d\t %d\t %d\t %.3f\t %.3f\t %.3f\t%.3f\t %.3f\t %.3f\n', subid, subage, gender, group, block, trial, presentedItem, is_correct, keypressed, correct, rt, atResp, atEnc(1), atEnc(2),atEnc(3),atRet);
                        end
                        writelog(strcat('KEY Keycode ', KbName(keypressed) ,' Correct ', num2str(correct) ,' Reaction time ', num2str(rt) , ' Accumulated time', num2str(atResp))); % at this point the accumulated time of encoding is not written, since just retrieval is happening and collected
                    elseif firstPress(escKey)>0
                        ShowCursor;
                        fprintf(outfile, 'ABORTED\n');
                        writelog('EXIT User quit');
                        fclose(outfile);
                        fclose(logfile);
                        Screen('CloseAll');
                        return
                    end
                end
            elseif ~keyIsDown
                keyLastDown = false;
            end
        end
        if keypressed == -1
            correct = 0; % if keypressed == -1 (that is, no key is pressed), then correct / accuracy is 0
            atResp = GetSecs() - ScannerStartTime; % at (accumulated time) uses a low-level function that is FirstPress and this comes from KbQueueCheck (this is better because it requires less computational online performance than a structure)
            % PRINTS EXPERIMENT DATA IN COMMAND WINDOW
            fprintf(outfile,'%s\t %s\t %s\t %s\t %d\t %d\t %s\t %d\t %d\t %d\t %.3f\t %.3f\t %.3f\t%.3f\t %.3f\t %.3f\n', subid, subage, gender, group, block, trial, presentedItem, is_correct, keypressed, correct, rt, atEnc(1), atEnc(2),atEnc(3),atRet, atResp);
            writelog('INFO No keypress');
        end
        
        % STRUCTURES TO COLLECT BEHAVIORAL DATA
        accuracy(trial, block, task) = correct;
        results.accuracy = accuracy;
        
        reaction_time(trial, block, task) = rt;
        results.reaction_time = reaction_time;
        
        encodingLetters{trial, block,task} = letters(shownLetters);
        results.encodingLetters = encodingLetters;
       
        acc_time_encoding(trial, block,task) = atEnc(i); % prints accumulated time of every Encoding letter (1,2,3)
        results.times_encoding = acc_time_encoding;
        
        acc_time_retrieval(trial, block, task) = atRet;  % prints accumulated time at the presentation of Retrieval
        results.times_retrieval = acc_time_retrieval;
        
        acc_time_response(trial, block, task) = atResp;  % prints accumulated time at Response (key press)
        results.accumulated_time = acc_time_response;
        
        save('C:\Projekte\fMRI-children-Rolandic\working-memory\experiments\results', 'accuracy', 'reaction_time', 'encodingLetters', 'acc_time_encoding', 'acc_time_retrieval', 'acc_time_response'); % save results of structures into .mat file
        % save('C:\toolbox\working-memory\experiments\results', 'accuracy', 'reaction_time', 'encodingLetters', 'acc_time_encoding', 'acc_time_retrieval', 'acc_time_response'); % save results of structures into .mat file
        
        %% Inter-Trial Interval
        Screen('FillRect', mainwin, bgcolor);
        Screen('TextSize', mainwin, fontsize*2);
        Screen('DrawLine', mainwin, textcolor, center(1)-50, center(2), center(1)+50, center(2) ,3);
        Screen('DrawLine', mainwin, textcolor, center(1), center(2)-50, center(1), center(2)+50 ,3);
        Screen('Flip', mainwin);
        writelog('SHOW Inter-interval screen');

        if trial<=nTrialsPerBlock*tasks(blocks(block))
            WaitSecs(interTrialInterval(randi(3)));
        end
    end  % end of trial loop
    set(blocks(block)) = set(blocks(block))+1;
end % end of block loop
writelog('EXIT Experiment finished');
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
% outstring = sprintf('%s - %.3f - %s\n',datestr(now,'HH:MM:ss.FFF'),elapsedtime,out);
outstring = sprintf('%s - %6.3f : %s\n',datestr(now,'HH:MM:ss.FFF'),elapsedtime,out);
fprintf(logfile, '%s', outstring);
fprintf('%s',outstring);
end

function time = stopwatch(code) % As a variable stopwatch uses additional variables and operations to GetSecs, and this is faster with the at variable that calls FirstPress-KbQueueCheck
persistent lasttime % persistent variable that allows to keep its values constant (last lap)
persistent starttime
if isempty(code)
    starttime = GetSecs();
    lasttime = starttime;
    return
end

if code == 1    %% runtime
    time = GetSecs()- starttime; % current time minus starttime (since Stopwatch was reset or started)
elseif code == 2 %% lap time
    time = GetSecs()- lasttime; % time since the last lap or time since last reset (if it has never been called)
    lasttime = GetSecs();
elseif code>2 %% set start time externally, assuming it is never below 24
    starttime = code;
    lasttime = starttime;
end
end

function SendSignal(onof)
 
    ioObj = io64;
    %status = io32(ioObj);
    address = hex2dec('D050');%standard LPT1 output port address
    status = io64(ioObj);
    io64(ioObj, address, onof);
    
end
