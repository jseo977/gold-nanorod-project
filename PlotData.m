function  PlotData( Data2Save )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
Num=length(Data2Save);

for i=1:Num
    A=Data2Save{i};
    Data=A{1};
    Time=Data(:,1);
    Recording=Data(:,2);
    ElecStim=Data(:,4);
    OptStim=Data(:,5);
    fig = figure(); hold on;
    yyaxis left
    plot(Time,Recording*1e3,'k');
    %ylim([-65, 30])
    ylabel ('Membrane Potential (mV)')
    hold on;
    yyaxis right
    plot(Time,ElecStim,'b');
     yyaxis right
     plot(Time,OptStim,'Color', [1, 0, 0, 0.2]);
    
end

end
