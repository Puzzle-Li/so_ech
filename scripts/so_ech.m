% Plot for comparation of event correlation histgrams of slow oscillations 
% between two condition groups (auditory stimuli vs. sham)
%
% Created by Puzhe Li (lipzh@shanghaitech.edu.cn) on 2022-09-28

clc;
clear;
close all;
addpath(fileparts(mfilename));

%% Install the Fieldtrip
% If you don't have FieldTrip installed, download Fieldtrip. Then uncomment
% the next few lines to active the tool box, remember to rewrite the path
% of Fieldtrip installed. 

dn.ft = 'D:\Softwares\MATLAB\Codes\packages\fieldtrip\fieldtrip-20220104\fieldtrip-20220104';
addpath(dn.ft);
ft_defaults;

%% Plot event correlation histgram of slow ocsillations
dn.proj = 'C:\Users\HP\Documents\GitHub\projects\so_ech';
dn.data = fullfile(dn.proj,'data');
plotsoech(dn.data);
