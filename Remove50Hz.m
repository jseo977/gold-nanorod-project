function [dat_clean, t] = Remove50Hz(Data2Save)
dat = Data2Save{1}{1}(:,2);
t = Data2Save{1}{1}(:,1);

dt = mean(diff(t));
Fs = 1/dt;   % Sampling frequency (Hz)
f0 = 50;     % Power line frequency (Hz)
bw = 4;      % Notch width (Hz) — adjust if needed
low = (f0 - bw/2) / (Fs/2);
high = (f0 + bw/2) / (Fs/2);
[b, a] = butter(2, [low high], 'stop');   % 2nd-order bandstop filter
dat_clean = filtfilt(b, a, dat);
figure;
if false
    plot(t, dat, 'r'); hold on
end
plot(t, dat_clean, 'k')
legend('Original', '50 Hz Removed')
xlabel('Time')
ylabel('Signal')
title('Time Signal Before vs After 50 Hz Notch')
grid on
end