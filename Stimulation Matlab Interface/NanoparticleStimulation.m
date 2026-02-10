classdef HybridStimulation < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure

        FolderEditFieldLabel           matlab.ui.control.Label
        FolderEditField                matlab.ui.control.EditField

        FrequenciesHzEditFieldLabel    matlab.ui.control.Label
        FrequencyEditField             matlab.ui.control.NumericEditField

        CellNumberEditFieldLabel       matlab.ui.control.Label
        CellNumberEditField            matlab.ui.control.NumericEditField

        PulseRepeatsEditFieldLabel     matlab.ui.control.Label
        PulseRepeatsEditField          matlab.ui.control.NumericEditField

        PulsemsEditFieldLabel          matlab.ui.control.Label
        ElecPulseEditField             matlab.ui.control.NumericEditField
        MaxAmppAEditFieldLabel         matlab.ui.control.Label
        ElecMaxAmppAEditField          matlab.ui.control.NumericEditField
        ElecRandomCheckBox             matlab.ui.control.CheckBox
        OptRandomCheckBox              matlab.ui.control.CheckBox
        PulsemsEditField_2Label        matlab.ui.control.Label
        OptPulseEditField              matlab.ui.control.NumericEditField
        MaxAmp0or18004095Label         matlab.ui.control.Label
        OptMaxAmpEditField             matlab.ui.control.NumericEditField
        CheckWaveformButton            matlab.ui.control.Button
        StimulateButton                matlab.ui.control.Button
        InitiateButton                 matlab.ui.control.Button
        OpticalDelaymsmin20msLabel     matlab.ui.control.Label
        OpticalDelayEditField          matlab.ui.control.NumericEditField
        ElectricalWaveformCheckBox     matlab.ui.control.CheckBox
        OpticalWaveformCheckBox        matlab.ui.control.CheckBox
        UIOptAxes                      matlab.ui.control.UIAxes
        UIElecAxes                     matlab.ui.control.UIAxes
    end

    
    properties (Access = private)
        elecAmp =[]; % Electrical Stimulation Amplitudes
        optAmp = []; %Optical Stimulation Amplitudes
        elecs; %%National Device for electrical stimulation
        opts; %%Laser for optical stimulation
        elecWave=[];%%Electrical Stimulation Waveform
        optWave=[];%%Optical Stimulation Waveform (trigger)
        
        Delay=10 % Global Delay (ms)
    end
    
    methods (Access = private)
        function Wave = WaveformGenerator(app,pulse,delay,duration,fs,amp,frequency)
            %%duration:total stimulation time (s)
            %%fs: scanning frequency (Hz)
            %%pulse: single pulse width (ms)
            %%delay: intial delay (ms)
            %%amp: list of amplitudes
            %%frequency: stimulation frequency
            
            Wave=zeros(floor(duration*fs),1);
            OnePulseDuration=floor(1/frequency*fs);
            NumberofPulses=length(amp);
            for i=1:NumberofPulses
                k1=floor(delay*1e-3*fs);
                k2=floor((delay+pulse)*1e-3*fs);
                k1=(i-1)*OnePulseDuration+k1;
                k2=(i-1)*OnePulseDuration+k2;
                Wave(k1:k2)=amp(i);
            end
        end
        
        function laserstim = LaserStimulation(app,Amp,Pulse)
            %%%Setting up laser for stimulation
            % This is for controlling the blue light optogenetic stimulator from Optotech
            % The communication protocol is based on the REM benchtop stimulator protocol
            % All mesages to the laser must start with 'V1' and end with 'Z', the optional parametrs are
            % Jhhh     laser power DAC         (000 ... FFF)    Default = 0
            % Lhhhh    pre-pulse delay in us   (0000 ... FFFF)  Default = 0
            % Hhhhh    pulse on-time in us     (0000 ... FFFF)  Default = 3E8 (1ms)
            % Phhhh    pulse period time in us (0000 ... FFFF)  Default = 7530 (30ms)
            % Nhhhh    Number of repititions   (0000 ... FFFF)  Default = 100 (256 repetitions)
            % Yn       Background illumination (0=None, 1=On)   Default = 1
            % Th       Trigger options         (0 = None, 1 = Free run; 2= Positive edge; 3=Negative edge) Default =0
            % All hex values must be zero-buffered (ie: for D00FF)
            % An example message would be 'V1J100L0000H03E8P7530NA6400T2Z '
            % which would set 25600 pulses with a dealy of 0us at a power level of 256 (out of 4095) with the pulse train
            % begining on the positive edge of the trigger. The pulse total period is 30ms, while the laser is on only for the first 1ms of that period
            % Not all values need to be sent. The stimulator remembers the previously set parameters or the defaults, so only new parameters nee
            % to be updated. In that case, an example message might be 'V1J150Z', which would set the laser power to 336 digital units
            % while the rest of the settings remain default (or the last updated values if a command has already been sent)
            
            
            %% Laser turn on at roughly 1700 and its approximately linear from 1800.
            
            StimVoltage=dec2hex(Amp,3);
            StimDuration=dec2hex(Pulse*1000,4);
            lightstim=['V1J' StimVoltage 'H' StimDuration 'L0000' 'Y0N0001PFFFFT2Z'] 
            laserstim=lightstim;
            
        end
        
        function results = SaveData(app,Data2Save)
            %% Save Data
            
            Folder=app.FolderEditField.Value;
            CellNum=app.CellNumberEditField.Value;
            
            if(exist([Folder '/' date '/Cell' num2str(CellNum)],'file')==7)
            else
                mkdir([Folder '/' date '/Cell' num2str(CellNum)]);
            end
            saveString = [Folder '/' date '/Cell' num2str(CellNum) '/' Option];
            index = dir([saveString '*.mat']);
            index = sprintf('%03.0f', length(index)+1);
            savename=[saveString index];
            save(savename,'Data2Save');
            
            Freq = app.FrequencyEditField.Value;
            Pulses = app.PulseRepeatsEditField.Value;

            ElecPulse = app.ElecPulseEditField.Value;
            ElecMax = app.ElecMaxAmppAEditField.Value;
            ElecRandom = app.ElecRandomCheckBox.Value;
            
            OptPulse = app.OptPulseEditField.Value;
            OptMax = app.OptMaxAmpEditField.Value;
            OptRandom = app.OptRandomCheckBox.Value;
            OptDelay= app.OpticalDelayEditField.Value;
            
            fid = fopen([savename '.txt'],'w');
            
            T=sprintf('Freq: %.1f Hz\n',Freq);
            fprintf(fid,T);
            T=sprintf('Pulses: %d\n',Pulses);
            fprintf(fid,T);
            T=sprintf('\nElecValue : %d\n',ElecValue);
            fprintf(fid,T);
            T=sprintf('ElecPulse : %.1f ms\n',ElecPulse);
            fprintf(fid,T);
            T=sprintf('ElecMax : %.1f pA\n',ElecMax);
            fprintf(fid,T);
            T=sprintf('ElecMin : %.1f pA\n',ElecMin);
            fprintf(fid,T);
            T=sprintf('ElecRandom : %d\n',ElecRandom);
            fprintf(fid,T);
            
            T=sprintf('\nOptValue : %d\n',OptValue);
            fprintf(fid,T);
            T=sprintf('OptPulse : %.1f ms\n',OptPulse);
            fprintf(fid,T);
            T=sprintf('OptMax : %.1f pA\n',OptMax);
            fprintf(fid,T);
            T=sprintf('OptSteps : %d\n',OptStep);
            fprintf(fid,T);
            T=sprintf('OptRandom : %d\n',OptRandom);
            fprintf(fid,T);
            T=sprintf('OptDelay : %.1f ms\n',OptDelay);
            fprintf(fid,T);
            
            fclose(fid);
        end
        
    end
    

    methods (Access = private)

        % Button pushed function: InitiateButton
        function InitiateButtonPushed(app, event)
            %%%Enable both electrical and optical stimulation
            clc;
            app.elecs=daq.createSession('ni');
            app.elecs.Rate=20000;
            app.elecs.addAnalogOutputChannel('Dev3',0,'Voltage');%%Electrical Stimulation
            app.elecs.addAnalogOutputChannel('Dev3',1,'Voltage'); %%Optical Stimulation (Trigger output, linear to amp)
            app.elecs.addAnalogInputChannel('Dev3',4,'Voltage'); %%Membrane Potential
            app.elecs.addAnalogInputChannel('Dev3',7,'Voltage') %%Optical Stimulation (Trigger input)
            disp('Electrical Stimulation Ready')
            app.FrequenciesHzEditFieldLabel.Enable = 'on';
            app.FrequencyEditField.Enable = 'on';
            app.PulseRepeatsEditFieldLabel.Enable = 'on';
            app.PulseRepeatsEditField.Enable = 'on';
            
            %% Initiate Electrical Stimulation
            %             %% Needs Updates
          
            %   code below for Matlab 2020a
            %            addinput(app.elecs,'Dev1',4,'Voltage');%%Membrane Potential
            %             addinput(app.elecs,'Dev1',7,'Voltage');%%Optical Stimulation (Trigger input, linear to amp)
            %             addoutput(app.elecs,'Dev1',0,'Voltage'); %%Electrical Stimulation
            %             addoutput(app.elecs,'Dev1',1,'Voltage'); %%Optical Stimulation Trigger
            %
            %             %% Initiate Optical Stimulation
                        app.opts=serial('COM5');
            
        end

        % Value changed function: OptionsDropDown
        % function OptionsDropDownValueChanged(app, event)
        %     %%%Set up different stimulation options
        % 
        %     value = app.OptionsDropDown.Value;
        % 
        %     %%Electrical
        %     app.PulsemsEditFieldLabel.Enable = 'off';
        %     app.ElecPulseEditField.Enable = 'off';
        %     app.MaxAmppAEditFieldLabel.Enable = 'off';
        %     app.ElecMaxAmppAEditField.Enable = 'off';
        %     app.ElecRandomCheckBox.Enable = 'off';
        %     app.ElecRandomCheckBox.Value = false;
        %     %%Optical
        %     app.PulsemsEditField_2Label.Enable = 'off';
        %     app.OptPulseEditField.Enable = 'off';
        %     app.MaxAmp0or18004095Label.Enable = 'off';
        %     app.OptMaxAmpEditField.Enable = 'off';
        %     app.OptRandomCheckBox.Enable = 'off';
        %     app.OptRandomCheckBox.Value= false;
        %     app.OpticalDelayEditField.Enable = 'off';
        %     app.CheckWaveformButton.Enable = 'off';
        %     app.StimulateButton.Enable = 'off';
        % 
        %     switch value
        %         case 'Single Amplitude'
        %             %%Electrical
        %             app.PulsemsEditFieldLabel.Enable = 'on';
        %             app.ElecPulseEditField.Enable = 'on';
        %             app.MaxAmppAEditFieldLabel.Enable = 'on';
        %             app.ElecMaxAmppAEditField.Enable = 'on';
        %             %%Optical
        %             app.PulsemsEditField_2Label.Enable = 'on';
        %             app.OptPulseEditField.Enable = 'on';
        %             app.MaxAmp0or18004095Label.Enable = 'on';
        %             app.OptMaxAmpEditField.Enable = 'on';
        %             app.CheckWaveformButton.Enable = 'on';
        %             app.OpticalDelayEditField.Enable = 'on';
        % 
        %         case 'Electrical Threshold Check'
        %             %%Electrical
        %             app.PulsemsEditFieldLabel.Enable = 'on';
        %             app.ElecPulseEditField.Enable = 'on';
        %             app.MaxAmppAEditFieldLabel.Enable = 'on';
        %             app.ElecMaxAmppAEditField.Enable = 'on';
        %             app.ElecRandomCheckBox.Enable = 'on';
        %             app.CheckWaveformButton.Enable = 'on';
        % 
        %         case 'Optical Threshold Check'
        %             %%Optical
        %             app.PulsemsEditField_2Label.Enable = 'on';
        %             app.OptPulseEditField.Enable = 'on';
        %             app.MaxAmp0or18004095Label.Enable = 'on';
        %             app.OptMaxAmpEditField.Enable = 'on';
        %             app.OptRandomCheckBox.Enable = 'on';
        %             app.CheckWaveformButton.Enable = 'on';
        %             app.OpticalDelayEditField.Enable = 'on';
        % 
        %         case 'Hybrid Stimulation Threshold Check'
        %             %%Electrical
        %             app.PulsemsEditFieldLabel.Enable = 'on';
        %             app.ElecPulseEditField.Enable = 'on';
        %             app.MaxAmppAEditFieldLabel.Enable = 'on';
        %             app.ElecMaxAmppAEditField.Enable = 'on';
        %             app.ElecRandomCheckBox.Enable = 'on';
        %             %%Optical
        %             app.PulsemsEditField_2Label.Enable = 'on';
        %             app.OptPulseEditField.Enable = 'on';
        %             app.MaxAmp0or18004095Label.Enable = 'on';
        %             app.OptMaxAmpEditField.Enable = 'on';
        %             app.OptRandomCheckBox.Enable = 'on';
        %             app.CheckWaveformButton.Enable = 'on';
        %             app.OpticalDelayEditField.Enable = 'on';
        % 
        %         otherwise
        %     end
        % 
        % end

        % Button pushed function: CheckWaveformButton
        function CheckWaveformButtonPushed(app, event)
            close all;
            cla(app.UIOptAxes);
            cla(app.UIElecAxes);
            %             app.ElectricalWaveformCheckBox.Enable = 'on';
            %             app.OpticalWaveformCheckBox.Enable = 'on';
            Delay = app.Delay; %%20ms delay for all stimulation
            Freq = app.FrequencyEditField.Value;
            Pulses = app.PulseRepeatsEditField.Value;
            
            ElecPulse = app.ElecPulseEditField.Value;
            ElecMax = app.ElecMaxAmppAEditField.Value;
            ElecRandom = app.ElecRandomCheckBox.Value;
            
            if ElecValue == 0
                ElecMax = 0;
                ElecMin = 0;
                ElecStep = 1;
                ElecRandom = 0;
            end

            OptPulse = app.OptPulseEditField.Value;
            OptMax = app.OptMaxAmpEditField.Value;
            OptRandom = app.OptRandomCheckBox.Value;
            OptDelay= app.OpticalDelayEditField.Value;
            
            if OptValue == 0
                OptMax = 0;
                OptStep = 1;
                OptRandom = 0;
            end
            
            Duration = Pulses * ElecStep / Freq; %%Stimulation Duration
            fs = 20000;%%%Update when using NI
            dt=1/fs;
            if ElecStep>1
                Elecamp = ElecMin : (ElecMax-ElecMin)/(ElecStep-1): ElecMax;
            else
                Elecamp = ElecMax;
            end
            Elecamp = repmat(Elecamp,Pulses,1);
            Elecamp = Elecamp(:);
            
            ElecAmp=[];
            for i=1:OptStep
                if ElecRandom == 1
                    ElecAmp = [ElecAmp Elecamp(randperm(length(Elecamp)))];
                else
                    ElecAmp = [ElecAmp Elecamp];
                end
            end
            
            if OptStep>1
                Optamp=OptMin : (OptMax-OptMin)/(OptStep-1): OptMax;
            else
                Optamp=OptMax;
            end
            
            if OptRandom == 1
                Optamp = Optamp(randperm(length(Optamp)));
            end
            
            OptAmp=repmat(Optamp,Pulses*ElecStep,1);
            for i=1:OptStep
                ElecWave(:,i)=WaveformGenerator(app,ElecPulse,Delay,Duration,fs,ElecAmp(:,i),Freq);
                OptWave(:,i) = WaveformGenerator (app,OptPulse,OptDelay+Delay,Duration,fs,OptAmp(:,i),Freq);
            end
            T=dt:dt:dt*length(ElecWave(:,1));
            %             hold(app.UIAxes,'on');
            
            plot(app.UIElecAxes,T,ElecWave(:,1),'b');
            
            plot(app.UIOptAxes,T,OptWave(:,1),'r');
            %             legend(app.UIAxes,'Electrical','Optical');
            %             hold(app.UIAxes,'off');
            
            if OptStep>1
                j=0; figure();
                for i=1:OptStep
                    if j>9
                        j=0;figure();
                    end
                    j=j+1;
                    p=subplot(5,2,j);hold on;title(num2str(j))
                    yyaxis left;
                    plot(p,T,ElecWave(:,i),'b');
                    if ElecMax>0
                        ylim([0,ElecMax]);
                    elseif ElecMax<0
                        ylim([ElecMax,0]);
                    end
                    yyaxis right;
                    plot(p,T,OptWave(:,i),'r');
                    ylim([0,OptMax]);
                end
            end
            
            app.elecAmp=ElecAmp;
            app.optAmp=OptAmp;
            app.elecWave=ElecWave;
            app.optWave=OptWave;
            app.StimulateButton.Enable = 'on';
            
        end

        % Button pushed function: StimulateButton
        function StimulateButtonPushed(app, event)
            close all;
            ElecWave=app.elecWave;
            OptWave=app.optWave;
            ElecAmp=app.elecAmp;
            OptAmp=app.optAmp;
            OptPulse = app.OptPulseEditField.Value;
            Omax=max(OptAmp(:));
            
                        opt=app.opts;
            fs=20000;
            dt=1/fs;
            
            Data2Save={};
            
            for i=1:OptStep
                %%%Matlab manual
                % simutaneous read and write channel
                % https://au.mathworks.com/help/daq/daq.interfaces.dataacquisition.readwrite.html
                response=[];
                time=[];
                Data=[];
                fprintf('Recording.... Stimulation %d/%d\n',i,OptStep);
%                 pause(3);
%                 figure(i);hold on;
%                 plot(ElecWave(:,i));plot(OptWave(:,i));
                
                                laserstim=LaserStimulation(app,OptAmp(1,i),OptPulse);
                                fopen(opt);
                                fprintf(opt,laserstim);
                
                
                                outScanData=[ElecWave(:,i)/100,OptWave(:,i)/1000];
                                app.elecs.queueOutputData(outScanData);
                                [response,time]=app.elecs.startForeground();
                                app.elecs.stop;
                                app.elecs.release;
                                Data(:,1)=time;
                                Data(:,2)=response(:,1)/10;
                                Data(:,3)=response(:,2);
                                Data(:,4)=ElecWave(:,i);
                                Data(:,5)=OptWave(:,i);
                                figure(i); hold on;
                                yyaxis left;
                                h1=plot(time,Data(:,2),'-k');
                                if max(Data(:,4))>0
                                h2=plot(time,Data(:,4),'-b');
                                end
                                yyaxis right;
                                if max(Data(:,5)>0)
                                h3=plot(time,Data(:,3)*1000,'r');
                                ylim([0,Omax]);
                                end
%                                 legend([h1,h2,h3],{'Recording','Elec stim','Optical stim'});
                                %% MATLAB 2020A
                %                 inScanData = readwrite(d,outScanData,"OutputFormat","Matrix")
                %                 Data=[inScanData;outScanData];
                %                 T=dt:dt:dt*length(Data);
                %                 figure(i);hold on;
                %                 %%%Need to update
                %                 h1=plot(T,Data(:,1)*100 ,'-k');hold on;
                %                 h2= plot(T,Data(:,3), '-b');
                %                 h3=  plot(T,Data(:,4), '-r');
                %                 legend([h1,h2,h3],{'Recording','Elec stim','Optical stim'});
                
                Data2Save{i}={Data,ElecAmp,OptAmp};
                fclose(opt);
            end
%             fclose(opt);
            SaveData(app,Data2Save);
            fprintf('Finished!\n');
            
        end

        % Value changed function: OpticalWaveformCheckBox
        function OpticalWaveformCheckBoxValueChanged(app, event)
            %             OptValue = app.OpticalWaveformCheckBox.Value;
            %             ElecValue = app.ElectricalWaveformCheckBox.Value;
            %             ElecWave = app.elecWave;
            %             OptWave = app.optWave;
            %             ElecWave=ElecWave(:,1);
            %             OptWave=OptWave(:,1);
            %             fs=20000;dt=1/fs;
            %             T=dt:dt:dt*length(ElecWave);
            %
            %             p=app.UIAxes;
            %             cla(p);
            %             delete(p.Children);
            %
            %             if OptValue == 1 & ElecValue ==1
            %                 yyaxis(app.UIAxes,'left');
            %                 plot(app.UIAxes,T,ElecWave(:,1),'b');
            %                 yyaxis(app.UIAxes,'right');
            %                 plot(app.UIAxes,T,OptWave(:,1),'r');
            %                 legend(app.UIAxes,'Electrical','Optical');
            %             elseif OptValue == 1 & ElecValue ==0
            %                 yyaxis(app.UIAxes,'right');
            %                 plot(app.UIAxes,T,OptWave(:,1),'r');
            %                 legend(app.UIAxes,'Optical');
            %             elseif OptValue == 0 & ElecValue ==1
            %                 yyaxis(app.UIAxes,'left');
            %                 plot(app.UIAxes,T,ElecWave(:,1),'b');
            %                 legend(app.UIAxes,'Electrical');
            %             end
        end

        % Value changed function: ElectricalWaveformCheckBox
        function ElectricalWaveformCheckBoxValueChanged(app, event)
            
            %             OptValue = app.OpticalWaveformCheckBox.Value;
            %             ElecValue = app.ElectricalWaveformCheckBox.Value;
            %             ElecWave = app.elecWave;
            %             OptWave = app.optWave;
            %             ElecWave=ElecWave(:,1);
            %             OptWave=OptWave(:,1);
            %             fs=20000;dt=1/fs;
            %             T=dt:dt:dt*length(ElecWave);
            %
            %             p=app.UIAxes;
            %
            % %             cla(p);
            % %             delete(p.Children);
            %             a=findobj(p, 'Type','line')
            %
            %             if OptValue == 1 & ElecValue ==1
            %                 yyaxis(app.UIAxes,'left');
            %                 plot(app.UIAxes,T,ElecWave(:,1),'b');
            %                 yyaxis(app.UIAxes,'right');
            %                 plot(app.UIAxes,T,OptWave(:,1),'r');
            %                 legend(app.UIAxes,'Electrical','Optical');
            %             elseif OptValue == 1 & ElecValue ==0
            %                 yyaxis(app.UIAxes,'right');
            %                 plot(app.UIAxes,T,OptWave(:,1),'r');
            %                 legend(app.UIAxes,'Optical');
            %             elseif OptValue == 0 & ElecValue ==1
            %                 yyaxis(app.UIAxes,'left');
            %                 plot(app.UIAxes,T,ElecWave(:,1),'b');
            %                 legend(app.UIAxes,'Electrical');
            %             end
        end
    end

    % App initialization and construction
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure
            app.UIFigure = uifigure;
            app.UIFigure.Position = [100 100 648 567];
            app.UIFigure.Name = 'Stimulation Sweep Interface';

            % Create FolderEditFieldLabel
            app.FolderEditFieldLabel = uilabel(app.UIFigure);
            app.FolderEditFieldLabel.HorizontalAlignment = 'right';
            app.FolderEditFieldLabel.Position = [60 540 39 22];
            app.FolderEditFieldLabel.Text = 'Folder';

            % Create FolderEditField
            app.FolderEditField = uieditfield(app.UIFigure, 'text');
            app.FolderEditField.Position = [114 540 100 22];
            app.FolderEditField.Value = 'Jae Min';

            % Create FrequenciesHzEditFieldLabel
            app.FrequenciesHzEditFieldLabel = uilabel(app.UIFigure);
            app.FrequenciesHzEditFieldLabel.HorizontalAlignment = 'right';
            app.FrequenciesHzEditFieldLabel.Enable = 'off';
            app.FrequenciesHzEditFieldLabel.Position = [13 474 86 22];
            app.FrequenciesHzEditFieldLabel.Text = 'Frequencies (Hz)';

            % Create FrequencyEditField
            app.FrequencyEditField = uieditfield(app.UIFigure, 'numeric');
            app.FrequencyEditField.Limits = [0 Inf];
            app.FrequencyEditField.Enable = 'off';
            app.FrequencyEditField.Position = [114 474 100 22];
            app.FrequencyEditField.Value = 2;

            % Create CellNumberEditFieldLabel
            app.CellNumberEditFieldLabel = uilabel(app.UIFigure);
            app.CellNumberEditFieldLabel.HorizontalAlignment = 'right';
            app.CellNumberEditFieldLabel.Position = [27 507 72 22];
            app.CellNumberEditFieldLabel.Text = 'Cell Number';

            % Create CellNumberEditField
            app.CellNumberEditField = uieditfield(app.UIFigure, 'numeric');
            app.CellNumberEditField.Position = [114 507 100 22];

            % Create PulseRepeatsEditFieldLabel
            app.PulseRepeatsEditFieldLabel = uilabel(app.UIFigure);
            app.PulseRepeatsEditFieldLabel.HorizontalAlignment = 'right';
            app.PulseRepeatsEditFieldLabel.Enable = 'off';
            app.PulseRepeatsEditFieldLabel.Position = [16 442 83 22];
            app.PulseRepeatsEditFieldLabel.Text = 'Pulse Repeats';

            % Create PulseRepeatsEditField
            app.PulseRepeatsEditField = uieditfield(app.UIFigure, 'numeric');
            app.PulseRepeatsEditField.Limits = [0 Inf];
            app.PulseRepeatsEditField.Enable = 'off';
            app.PulseRepeatsEditField.Position = [114 442 100 22];
            app.PulseRepeatsEditField.Value = 10;

            % Create PulsemsEditFieldLabel
            app.PulsemsEditFieldLabel = uilabel(app.UIFigure);
            app.PulsemsEditFieldLabel.HorizontalAlignment = 'right';
            app.PulsemsEditFieldLabel.Enable = 'off';
            app.PulsemsEditFieldLabel.Position = [38 334 61 22];
            app.PulsemsEditFieldLabel.Text = 'Pulse (ms)';

            % Create ElecPulseEditField
            app.ElecPulseEditField = uieditfield(app.UIFigure, 'numeric');
            app.ElecPulseEditField.Enable = 'off';
            app.ElecPulseEditField.Position = [114 334 100 22];
            app.ElecPulseEditField.Value = 3;

            % Create MaxAmppAEditFieldLabel
            app.MaxAmppAEditFieldLabel = uilabel(app.UIFigure);
            app.MaxAmppAEditFieldLabel.HorizontalAlignment = 'right';
            app.MaxAmppAEditFieldLabel.Enable = 'off';
            app.MaxAmppAEditFieldLabel.Position = [17 304 82 22];
            app.MaxAmppAEditFieldLabel.Text = 'Max Amp (pA)';

            % Create ElecMaxAmppAEditField
            app.ElecMaxAmppAEditField = uieditfield(app.UIFigure, 'numeric');
            app.ElecMaxAmppAEditField.Enable = 'off';
            app.ElecMaxAmppAEditField.Position = [114 304 100 22];

            % Create ElecRandomCheckBox
            app.ElecRandomCheckBox = uicheckbox(app.UIFigure);
            app.ElecRandomCheckBox.Enable = 'off';
            app.ElecRandomCheckBox.Text = 'Random';
            app.ElecRandomCheckBox.Position = [161 364 68 22];

            % Create OptRandomCheckBox
            app.OptRandomCheckBox = uicheckbox(app.UIFigure);
            app.OptRandomCheckBox.Enable = 'off';
            app.OptRandomCheckBox.Text = 'Random';
            app.OptRandomCheckBox.Position = [161 214 68 22];

            % Create PulsemsEditField_2Label
            app.PulsemsEditField_2Label = uilabel(app.UIFigure);
            app.PulsemsEditField_2Label.HorizontalAlignment = 'right';
            app.PulsemsEditField_2Label.Enable = 'off';
            app.PulsemsEditField_2Label.Position = [38 184 61 22];
            app.PulsemsEditField_2Label.Text = 'Pulse (ms)';

            % Create OptPulseEditField
            app.OptPulseEditField = uieditfield(app.UIFigure, 'numeric');
            app.OptPulseEditField.Enable = 'off';
            app.OptPulseEditField.Position = [114 184 100 22];
            app.OptPulseEditField.Value = 10;

            % Create MaxAmp0or18004095Label
            app.MaxAmp0or18004095Label = uilabel(app.UIFigure);
            app.MaxAmp0or18004095Label.HorizontalAlignment = 'right';
            app.MaxAmp0or18004095Label.Enable = 'off';
            app.MaxAmp0or18004095Label.Position = [8 147 91 28];
            app.MaxAmp0or18004095Label.Text = {'Max Amp'; '(0 or 1800-4095'};

            % Create OptMaxAmpEditField
            app.OptMaxAmpEditField = uieditfield(app.UIFigure, 'numeric');
            app.OptMaxAmpEditField.Limits = [0 4095];
            app.OptMaxAmpEditField.Enable = 'off';
            app.OptMaxAmpEditField.Position = [114 153 100 22];

            % Create CheckWaveformButton
            app.CheckWaveformButton = uibutton(app.UIFigure, 'push');
            app.CheckWaveformButton.ButtonPushedFcn = createCallbackFcn(app, @CheckWaveformButtonPushed, true);
            app.CheckWaveformButton.Enable = 'off';
            app.CheckWaveformButton.Position = [388 103 108 22];
            app.CheckWaveformButton.Text = 'Check Waveform';

            % Create StimulateButton
            app.StimulateButton = uibutton(app.UIFigure, 'push');
            app.StimulateButton.ButtonPushedFcn = createCallbackFcn(app, @StimulateButtonPushed, true);
            app.StimulateButton.Enable = 'off';
            app.StimulateButton.Position = [531 103 100 22];
            app.StimulateButton.Text = 'Stimulate';

            % Create InitiateButton
            app.InitiateButton = uibutton(app.UIFigure, 'push');
            app.InitiateButton.ButtonPushedFcn = createCallbackFcn(app, @InitiateButtonPushed, true);
            app.InitiateButton.Position = [228 540 100 22];
            app.InitiateButton.Text = 'Initiate';

            % Create OpticalDelaymsmin20msLabel
            app.OpticalDelaymsmin20msLabel = uilabel(app.UIFigure);
            app.OpticalDelaymsmin20msLabel.HorizontalAlignment = 'right';
            app.OpticalDelaymsmin20msLabel.Enable = 'off';
            app.OpticalDelaymsmin20msLabel.Position = [5 43 167 19];
            app.OpticalDelaymsmin20msLabel.Text = 'Optical Delay (ms)(min:-20ms)';

            % Create OpticalDelayEditField
            app.OpticalDelayEditField = uieditfield(app.UIFigure, 'numeric');
            app.OpticalDelayEditField.Limits = [-20 400];
            app.OpticalDelayEditField.Enable = 'off';
            app.OpticalDelayEditField.Position = [179 41 100 22];

            % Create ElectricalWaveformCheckBox
            app.ElectricalWaveformCheckBox = uicheckbox(app.UIFigure);
            app.ElectricalWaveformCheckBox.ValueChangedFcn = createCallbackFcn(app, @ElectricalWaveformCheckBoxValueChanged, true);
            app.ElectricalWaveformCheckBox.Enable = 'off';
            app.ElectricalWaveformCheckBox.Text = 'Electrical Waveform';
            app.ElectricalWaveformCheckBox.Position = [519 540 128 22];
            app.ElectricalWaveformCheckBox.Value = true;

            % Create OpticalWaveformCheckBox
            app.OpticalWaveformCheckBox = uicheckbox(app.UIFigure);
            app.OpticalWaveformCheckBox.ValueChangedFcn = createCallbackFcn(app, @OpticalWaveformCheckBoxValueChanged, true);
            app.OpticalWaveformCheckBox.Enable = 'off';
            app.OpticalWaveformCheckBox.Text = 'Optical Waveform';
            app.OpticalWaveformCheckBox.Position = [519 518 118 22];
            app.OpticalWaveformCheckBox.Value = true;

            % Create UIOptAxes
            app.UIOptAxes = uiaxes(app.UIFigure);
            app.UIOptAxes.PlotBoxAspectRatio = [2.53488372093023 1 1];
            app.UIOptAxes.YGrid = 'on';
            app.UIOptAxes.Position = [255 133 376 185];

            % Create UIElecAxes
            app.UIElecAxes = uiaxes(app.UIFigure);
            app.UIElecAxes.PlotBoxAspectRatio = [2.53488372093023 1 1];
            app.UIElecAxes.YGrid = 'on';
            app.UIElecAxes.Position = [255 323 376 185];
        end
    end

    methods (Access = public)

        % Construct app
        function app = HybridStimulation

            % Create and configure components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end