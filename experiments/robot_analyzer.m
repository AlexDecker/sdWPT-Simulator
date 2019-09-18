%Receives as parameter a table which represents a temporal series of the receiving voltage
%The first column of the table corresponds to the time (ms) and the second to the voltage 
%readings (1024/5 scale). The first threshold corresponds to the minimal value for the
%voltage values to be considered non-zero. The second one is a time interval used to identify
%when a zero-voltage point is considered inside a charging period
function statistics = robot_analyzer(voltages,threshold1, threshold2)
    
    threshold1 = 1024*threshold1/5;
        
    voltages = sortrows(voltages,1);%increasing in time
    voltages = [[0,0];voltages;[max(voltages(:,1))+1,0]];%dummie rows added

    %unique readings (takes the last occourance because it may be a correction of a bad
    %read value
    %[~,~,ind] = unique(voltages(:,1));
    %voltages = voltages(ind,:);

    [l,~] = size(voltages);
    
    %set of the identified charging periods. This vector alternates between the number of
    %consecutives lowVoltage values and highVoltage values, starting from lowVoltage. Thus,
    %11000111100 will be represented as 02342
    blobs = [];
    
    counter = 0;
    countingLow = true;%start counting low voltages

    for i=2:l %here the dummie row makes sense
        if countingLow
            if voltages(i,2)<threshold1
                counter = counter+double(voltages(i,1)-voltages(i-1,1));
            else
                blobs = [blobs, counter];
                counter = double(voltages(i,1)-voltages(i-1,1));
                countingLow = false;
            end
        else
            if voltages(i,2)>=threshold1
                counter = counter+double(voltages(i,1)-voltages(i-1,1));
            else
                blobs = [blobs, counter];
                counter = double(voltages(i,1)-voltages(i-1,1));
                countingLow = true;
            end
        end
    end
    blobs = [blobs,counter];

    low = true;
    statistics = [];
    blob.interruptions = 0;
    blob.offlineTime = 0;
    blob.onlineTime = 0;
    blob.begin = 0;
    blob.end = 0;
    
    time = 0;

    for i=1:length(blobs)
        if low
            if blobs(i)<threshold2 && i~=length(blobs)
                blob.interruptions = blob.interruptions + 1;
                blob.offlineTime = blob.offlineTime + blobs(i);
            else
                blob.end = time;
                if blob.end>blob.begin
                    statistics = [statistics,blob];
                end
                blob.interruptions = 0;
                blob.offlineTime = 0;
                blob.onlineTime = 0;
                blob.begin = time+blobs(i);
            end
            low = false;
        else
            blob.onlineTime = blob.onlineTime + blobs(i);
            low = true;
        end
        time = time + blobs(i);
    end

    figure;
    hold on;
    m = 5*max(double(voltages(:,2)))/1024;
    for i=1:length(statistics)
        rectangle('Position',[statistics(i).begin,0,...
            statistics(i).end-statistics(i).begin,m],'FaceColor',[rand rand rand],...
            'EdgeColor','None');
    end
    plot(voltages(:,1),5*double(voltages(:,2))/1024,'.g');
end
