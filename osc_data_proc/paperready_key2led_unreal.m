% Sampling rate has been set to (1/Tinterval*2)
% In our measurements we set the samples so that 10% of the samples are
% from before the onset e.g. 100ms epoch -> -10ms ~ 90ms
% Time is zeroed on trigger when the keypress is detected with a falling threshold
% of 4.6V 

datapath = ['D:/data/oscilloscope_data/key2sw_unity_led/'];


sslist_paths = {'./sslists/key2swled_unreal_0ms_426.csv'}
fname_suffixes = {'UE426'};


scope_fs = 245100; % SPEC PER OSCILLOSCOPE AND SETUP
resamp_fs = 20000; % ADEQUATE NUMBER DETERMINED BY USER

peak_lengthx = 30; %% DEPENDS ON HMD/LED/HARDWARE setup
peakwindow_thresholdx = 0.9; %% ALSO DEPENDS ON SETUP
trig_threshold = 1; % DEPENDS ON SETUP

%valids_idx = zeros(1, measures);
%invalids_idx = zeros(1, measures);
dataAs = [];
dataBs = [];
datalpAs = [];
%sslist = ssesh{1};
peak_latencies = [];
peak_vs = [];


for fsetup=1:length(sslist_paths)
    ssfile = fopen(sslist_paths{fsetup});
    ssesh = textscan(ssfile, '%s', 'Delimiter', '\n');
    measures = length(ssesh{1});
    
    
    valids_idx = zeros(1, measures);
    invalids_idx = zeros(1, measures);
    dataAs = [];
    dataBs = [];
    datalpAs = [];
    sslist = ssesh{1};
    peak_latencies = [];
    peak_vs = [];
    
    
    

    for measure=1:measures
        clear A B LowPass_A_500_

        load(sslist{measure});

        if measure==1
            dataT = [Tstart+1/resamp_fs:1/resamp_fs:0.09]*1000;
            Tinterval_resamped = Tinterval * (scope_fs/resamp_fs);
            %sampcount_for_threswindow = 15
        end %endif

        % downsample from 245kHz to 10kHz?
        dataA = resample(A, resamp_fs, scope_fs);
        dataB = resample(B, resamp_fs, scope_fs);
        datalpA = resample(A, resamp_fs, scope_fs);





        % weeding out bad data 1: false-alarm triggers for LED
        if isempty(find(datalpA>1))
            invalids_idx(measure) = 1;
            continue;
        else
            valids_idx(measure) = 1;
        end %endif of checking for non above-threshold values (No LED triggered)



        % weeding out bad data 2: false-alarm triggers for HMD(not needed in LED)
        %


        % find peak 
        % for leds we have multiple peaks (5 per trial), but we only need the
        % first one
        % which means we have to find the first 

        threshold_cross1idx = find(datalpA>trig_threshold);
        if threshold_cross1idx(1) < 200
            % also a bad trial because that's too fast
            invalids_idx(measure) = 1;
            valids_idx(measure) = 0;
            continue;
        end

        dataAs = cat(2, dataAs, dataA);
        dataBs = cat(2, dataBs, dataB);
        datalpAs = cat(2, datalpAs, datalpA);

        probe_t = dataT(threshold_cross1idx(1):threshold_cross1idx(1)+peak_lengthx);
        probe_x = datalpA(threshold_cross1idx(1):threshold_cross1idx(1)+peak_lengthx);
        [peak, peak_t] = findpeaks(probe_x, probe_t);

        peak_latencies = [peak_latencies peak_t(1)];
        peak_vs = [peak_vs peak(1)];

    end % end of per measure loop

peak_key2led_unreal = peak_latencies;

    good_trialsn = length(valids_idx(valids_idx==1));
    bad_trialsn = length(invalids_idx(invalids_idx==1));

    figure;
    %subplot(2,1,1);
    tiledlayout(2,1, 'TileSpacing', 'compact', 'Padding', 'compact');
    nexttile;
    hold on;
    xline(0, 'LineWidth', 5, 'Alpha', 0.4);
    for good_trial=1:good_trialsn
        yyaxis left;
        plot(dataT, dataBs(:,good_trial), 'r-');
        yyaxis right;
        plot(dataT, datalpAs(:,good_trial), '-', 'Color', [0, 0.4470, 0.7410]);

    end % end of goodtrials loop
    yyaxis right;
    plot(peak_latencies, peak_vs, 'k.');



    % avearge good
    %figure;
    %subplot(2,1,2);
    nexttile;
    hold on;
    xline(0, 'LineWidth', 5, 'Alpha', 0.4);
    goodt_avg = mean(dataBs(:,good_trial), 2);
    goodx_avg = mean(datalpAs(:,good_trial), 2);
    yyaxis left;
    plot(dataT, goodt_avg, 'r');
    yyaxis right;
    plot(dataT, goodx_avg, 'Color', [0, 0.4470, 0.7410]);

    xlabel('Time (ms)')
    ylabel('Probe Voltage')

    xline(mean(peak_latencies), 'k');
    yline(mean(peak_vs), 'k');
    legend(['Keypress' fname_suffixes{fsetup} ' (LED)  N=' num2str(good_trial)], ...
         ['Key Sensor Probe'], ...
         ['Arduino LED Sensor Probe'], ...
         ['Mean peak ' num2str(mean(peak_latencies), '%.3f') 'ms (std. ' num2str(std(peak_latencies), '%.3f') 'ms)'], ...
         'Location','northeast');
    
    timingdata = struct;
    timingdata.dataAs = dataAs;
    timingdata.dataBs = dataBs;
    timingdata.datalpAs = datalpAs;
    timingdata.dataT = dataT;
    timingdata.goodtrial = good_trial;
    timingdata.peak_latencies = peak_latencies;
    timingdata.peak_vs = peak_vs;
    timingdata.valids_idx = valids_idx;
    
    savepath = ['./stats/key2unity_' fname_suffixes{fsetup} '.mat'];
                
                [filepath, filename]= fileparts(savepath);
                if ~exist(filepath, 'dir')
                  [parentdir, newdir]=fileparts(filepath);
                  [status,msg]= mkdir(parentdir, newdir);
                  if status~=1
                    error(msg);
                  end
                end
    save(savepath, 'timingdata');
    





end


