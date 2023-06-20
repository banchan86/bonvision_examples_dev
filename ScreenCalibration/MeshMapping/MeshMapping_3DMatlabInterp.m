%% Tomaso Muzzu - UCL - 09/03/2021
% edits by EH (March 2021).
% edits by EH (August 2021) - convert to cartesian co-ordinates and
% linearly spaced pixel interpolation

%% Mesh mapping modification from Matlab
% adapting meshmapping file obtained with Bonsai script. 
% Original is the name of the output of the Bonsai script

%% Variable assignment

inputFileName = 'Tron_MeshMap_Corrected2023-06-16T15_28_09.csv';
outputFileName = 'Tron_MeshMapping3D_MatlabOutput.bin';

DisplayDim = [1280 800]; % [horizontal_pixels, vertical_pixels]
AngularSpan = [240 120]; % [azimuth_deg, elevation_deg]
azimuthInterpValue = 6;
elevationInterpValue = 6;
plotFlag = true;

%% import csv file generated by Bonsai

[x_pix,y_pix,az_deg,el_deg] = importfile(inputFileName);


%% Perform interpolation
% Create arrary with 5 columns as follows: 
% [pixel_x, pixel_y, newpixel_x, newpixel_y, brightness]
MeshMapping = [x_pix,y_pix,az_deg,el_deg, ones(size(x_pix,1),1)];

% normalise coordinates
MeshMapping = sortrows(MeshMapping,3);
MeshMapping(:,3) = MeshMapping(:,3)/max(MeshMapping(:,3));
MeshMapping(:,4) = MeshMapping(:,4)/max(MeshMapping(:,4));

FX = scatteredInterpolant(MeshMapping(:,3),MeshMapping(:,4),MeshMapping(:,1),'natural');
FY = scatteredInterpolant(MeshMapping(:,3),MeshMapping(:,4),MeshMapping(:,2),'natural');
FI = scatteredInterpolant(MeshMapping(:,3),MeshMapping(:,4),MeshMapping(:,5),'natural');

AzRange = linspace(0,1,AngularSpan(1)/azimuthInterpValue);
ElRange = linspace(0,1,AngularSpan(2)/elevationInterpValue);
[newDegAz, newDegEl ]= meshgrid(AzRange,ElRange);
posX = FX(newDegAz,newDegEl);
posY = FY(newDegAz,newDegEl);
intensity = FI(newDegAz,newDegEl);


dataCell = [posX(:) -posY(:) newDegAz(:) newDegEl(:) intensity(:)];
MeshNormInterp = sortrows(dataCell,3);

if plotFlag
    figure
    subplot(121)
    plot(MeshMapping(:,1),MeshMapping(:,2),'or');
    title('Original mesh mapping file')
    subplot(122)
    plot(MeshMapping(:,1),MeshMapping(:,2),'ro');
    hold on
    plot(MeshNormInterp(:,1),-1.*MeshNormInterp(:,2),'k.')
    legend({'original data', 'interpolated data'})
    title('Interpolated mesh map file')
end


%% get linearly spaced coordinates in pixel-space

newX = (posX+1)/2;
newY = 1-((posY+1)/2);
min_x = min(posX(:)); max_x = max(posX(:));
min_y = min(posY(:)); max_y = max(posY(:));

%x_coords = round(min_x,3):0.001:round(max_x,3);
%y_coords = round(min_y,3):0.001:round(max_y,3);

[Xq, Yq] = meshgrid(0:0.001:1,0:0.001:1);

Az_interp = griddata(newX,newY,newDegAz,Xq,Yq,'natural');
El_interp = griddata(newX,newY,newDegEl,Xq,Yq,'natural');


%% convert back to real angles
max_Az = 120;
min_Az = -120;
max_El = 90;
min_El = -30;

Az_interp_angles = Az_interp.*(max_Az-min_Az) + min_Az;
El_interp_angles = El_interp.*(min_El-max_El) + max_El;


figure
subplot(121)
imagesc(Az_interp_angles), colorbar
title('Azimuth map')
subplot(122)
imagesc(El_interp_angles), colorbar
title('Elevation map')


%% convert from spherical to cartesian coordinates

% azimuth and elevation need some pre-processing
% Az_interp_angles = -1.*Az_interp_angles; % currently uncommented to
% improve Tron meshmapping alignment
[x,y,z] = sph2cart(deg2rad(Az_interp_angles), deg2rad(El_interp_angles),1);

figure
subplot(1,3,1)
imagesc(x); colorbar; title('x vector')
subplot(1,3,2)
imagesc(y);colorbar;title('y vector')
subplot(1,3,3)
imagesc(z);colorbar;title('z vector')

%% save as a binary

% M = cat(3,x,y,z);
M = cat(3,-x,y,z);

% % M = cat(3,-x,-y,z);ggg
% %M = cat(3,z,y,x);
% 
% %fid = fopen('MeshMap3dMatrix_xy.bin', 'w');
fid = fopen(outputFileName, 'w');

fwrite(fid,M,'double');
fclose(fid);

%% save as a binary (float32 version)

% % M = cat(3,x,y,z);
% % M = permute(cat(3,-x,y,z), [3 1 2]);
% M = cat(3,-x,y,z);
% M = reshape(M,[3,size(M,1),size(M,1)]);
% M = reshape(M,[],1);
% M = single(M);
% 
% % M = permute(cat(3,-x,y,z), [2 3 1]);
% 
% % M=M';
% % M = cat(3,-x,-y,z);
% %M = cat(3,z,y,x);
% % M = cat(3,-x,y,z);
% %fid = fopen('MeshMap3dMatrix_xy.bin', 'w');
% fid = fopen(outputFileName, 'w');
% 
% fwrite(fid,M,'float32');
% fclose(fid);

%% Save output file 2019a onwards
% writematrix(MeshNormInterp,outputFileName) 

%% for older vesions
%dlmwrite(outputFileName, MeshNormInterp, 'precision', 32)





%% function for importing csv (autogenerated using matlab)
function [x_pix,y_pix,az_deg,el_deg] = importfile(filename, startRow, endRow)
%IMPORTFILE Import numeric data from a text file as column vectors.
%   [X_PIX,Y_PIX,AZ_DEG,EL_DEG] = IMPORTFILE(FILENAME) Reads data from text
%   file FILENAME for the default selection.
%
%   [X_PIX,Y_PIX,AZ_DEG,EL_DEG] = IMPORTFILE(FILENAME, STARTROW, ENDROW)
%   Reads data from rows STARTROW through ENDROW of text file FILENAME.
%
% Example:
%   [x_pix,y_pix,az_deg,el_deg] = importfile('MeshMap_Corrected2021-03-17T17_09_50.csv',1, 65);
%
%    See also TEXTSCAN.

% Auto-generated by MATLAB on 2021/03/22 12:04:45

%% Initialize variables.
delimiter = ',';
if nargin<=2
    startRow = 1;
    endRow = inf;
end

%% Format for each line of text:
%   column1: double (%f)
%	column2: double (%f)
%   column3: double (%f)
%	column4: double (%f)
% For more information, see the TEXTSCAN documentation.
formatSpec = '%f%f%f%f%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to the format.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'TextType', 'string', 'HeaderLines', startRow(1)-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
for block=2:length(startRow)
    frewind(fileID);
    dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', delimiter, 'TextType', 'string', 'HeaderLines', startRow(block)-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
    for col=1:length(dataArray)
        dataArray{col} = [dataArray{col};dataArrayBlock{col}];
    end
end

%% Close the text file.
fclose(fileID);

%% Post processing for unimportable data.
% No unimportable data rules were applied during the import, so no post
% processing code is included. To generate code which works for
% unimportable data, select unimportable cells in a file and regenerate the
% script.

%% Allocate imported array to column variable names
x_pix = dataArray{:, 1};
y_pix = dataArray{:, 2};
az_deg = dataArray{:, 3};
el_deg = dataArray{:, 4};

end