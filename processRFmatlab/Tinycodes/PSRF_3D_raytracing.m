function [x_s, x_p, raylength_s, raylength_p, pplat_p, pplon_p, pplat_s, pplon_s, Tpds]=PSRF_3D_raytracing(datar, rayp, bazi, YAxisRange, model_path, stalat, stalon)

RFlength = size(datar,1); EV_num = size(datar, 2);
rayp=rayp';
bazi=bazi';
load(model_path)
TDepths(:,1) = model_3D.dep(1,1,:);
TLons(:,1) = model_3D.lon(:,1,1);
TLats(:,1) = model_3D.lat(1,:,1);

%% 3D raytracing

% Format matrix
    x_s=zeros(length(YAxisRange),EV_num);
    x_p=zeros(length(YAxisRange),EV_num);
    raylength_s=zeros(length(YAxisRange),EV_num);
    raylength_p=zeros(length(YAxisRange),EV_num);
    Tpds=zeros(length(YAxisRange),EV_num);
    pplat_p=zeros(length(YAxisRange),EV_num);
    pplon_p=zeros(length(YAxisRange),EV_num);
    pplat_s=zeros(length(YAxisRange),EV_num);
    pplon_s=zeros(length(YAxisRange),EV_num);
    
    pplat_p(1,:)=repmat(stalat,1,EV_num);
    pplon_p(1,:)=repmat(stalon,1,EV_num);
    pplat_s(1,:)=repmat(stalat,1,EV_num);
    pplon_s(1,:)=repmat(stalon,1,EV_num);
    
    dz = [0 diff(YAxisRange)];
    
    for i=1:length(YAxisRange) 
        
        disp(['computing in ' num2str(YAxisRange(i)) 'km depth'])
        
        R = 6371 - YAxisRange(i);
        
        xi=pplat_p(i,:);
        yi=pplon_p(i,:);
        
        if YAxisRange(i)<10
        zi=repmat(10,1,EV_num); 
        else
        zi=repmat(YAxisRange(i),1,EV_num);
        end
        
        Pierce_Vp=interp3(model_3D.lat,model_3D.lon,model_3D.dep,model_3D.Vp,xi,yi,zi);
        
        xi=pplat_s(i,:);
        yi=pplon_s(i,:);
        Pierce_Vs=interp3(model_3D.lat,model_3D.lon,model_3D.dep,model_3D.Vs,xi,yi,zi);
        
        x_p(i,:) = (dz(i)/R) ./ sqrt((1./(rayp.^2 .* (R./Pierce_Vp).^-2)) - 1);
        raylength_p(1,:) = (dz(i)*R) ./  (sqrt(((R./Pierce_Vp).^2) - (rayp.^2)).* Pierce_Vp);
        x_s(i,:) = (dz(i)/R) ./ sqrt((1./(rayp.^2.* (R./Pierce_Vs).^-2)) - 1);
        raylength_p(1,:) = (dz(i)*R) ./  (sqrt(((R./Pierce_Vs).^2) - (rayp.^2)).* Pierce_Vs);
        
        
        Tpds(i,:) = (sqrt((R./Pierce_Vs).^2 - rayp.^2) - sqrt((R./Pierce_Vp).^2 - rayp.^2)) .* (dz(i)/R);
        
        if i==1
            x_p_tem=x_p(1,:);
            x_s_tem=x_s(1,:);
        else
            x_p_tem=x_p_tem+x_p(i,:);
            x_s_tem=x_s_tem+x_p(i,:);
        end
        
        if i ~= length(YAxisRange)
        for k=1:EV_num
        [pplat_s(i+1,k), pplon_s(i+1,k)] = latlon_from(stalat,stalon,bazi(k),deg2km(rad2deg(x_s_tem(k))));
        [pplat_p(i+1,k), pplon_p(i+1,k)] = latlon_from(stalat,stalon,bazi(k),deg2km(rad2deg(x_p_tem(k))));
        end
        end
        
    end
    x_p=cumsum(x_p);
    x_s=cumsum(x_s);
    Tpds=cumsum(Tpds);
    

%% Convert the time axis to the depth axis
TimeAxis=((0:1:RFlength-1)*sampling-shift)';
PS_RFdepth = zeros(length(Depths),EV_num);
EndIndex = zeros(EV_num,1);
%Depthaxis =(0:1:700)';
%PS_RFdepth = zeros(701,EV_num);
 
for i = 1:EV_num
    TempTpds = Tpds(:,i);
StopIndex = find(imag(TempTpds),1);
if ~isempty(StopIndex)
    EndIndex(i) = StopIndex - 1;
else
    EndIndex(i) = length(Depths);
end

%PS_RFdepth(:,i) = interp1(Timeaxis,datar(:,i),Tpds(1:701,i));
   if isempty(StopIndex)
        DepthAxis = interp1(TempTpds,Depths,TimeAxis);
    else
        DepthAxis = interp1(TempTpds(1:(StopIndex-1)),Depths(1:(StopIndex-1)),TimeAxis);
   end   
    PS_RFTempAmps = datar(:,i);    
    ValueIndices = find (~isnan(DepthAxis));   
    
    
    %TPsdepth(i) = interp1(TimeAxis(ValueIndices),DepthAxis(ValueIndices),Tpds(29,i));
    %TPpPsdepth(i) = interp1(TimeAxis(ValueIndices),DepthAxis(ValueIndices),Tpppds(29,i));
    %TPsPsdepth(i) = interp1(TimeAxis(ValueIndices),DepthAxis(ValueIndices),Tpspds(29,i));
    
    if isempty(ValueIndices)   
        PS_RFAmps = TempTpds * NaN;        
    elseif max(ValueIndices) > length(PS_RFTempAmps)
        PS_RFAmps = TempTpds * NaN;  
        
    else
        PS_RFAmps = interp1(DepthAxis(ValueIndices),PS_RFTempAmps(ValueIndices),YAxisRange);
        PS_RFAmps = colvector(PS_RFAmps);
        PS_RFdepth(:,i) = PS_RFAmps/max(PS_RFAmps);        
    end    
end 
 
return