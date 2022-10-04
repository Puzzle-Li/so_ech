# Brief intro.
The X6 is a head-mounted single-channel electroencephalogram (EEG) device developed by Shanghai Quanlan Technology Co., LTD and can be based on white noise auditory stimulation during slow oscillations (SO) of sleep, which is reported to enhance memory consolidation in humans.  This mini project is to calculate stimulus-evoked SO and plot the event correlation histograms (ECH) in two conditions (stim.  vs. sham) among all sessions recorded from all subjects.  

# How to design
The pipeline of data process is referred to [a Neuron paper (2013)](https://www.cell.com/neuron/fulltext/S0896-6273(13)00230-4?_returnURL=https%3A%2F%2Flinkinghub.elsevier.com%2Fretrieve%2Fpii%2FS0896627313002304%3Fshowall%3Dtrue), in the 1st paragraph of section "EXPERIMENTAL PROCEDURES · Analyses of Sleep Measures and EEG · Offline Analyses of Slow Oscillations" in which all procedures were introduced and all parameters were set to default in this project codes.  
The result of the pipeline is to plot the ECH like figure 2b in this paper.  
![20221004165427](https://puzzle-li.oss-cn-shanghai.aliyuncs.com/picbed/markdown/20221004165427.png)  

# How to work
You can just add your data and logs about stimulus time points (`.edf` and `.bin` files) in a folder named "Stim###" or "Sham###" in `data` folder.  
![20221004164023](https://puzzle-li.oss-cn-shanghai.aliyuncs.com/picbed/markdown/20221004164023.png)  
At least add 2 stim and sham sessions respectively, then you can run the project.  
![20221004164223](https://puzzle-li.oss-cn-shanghai.aliyuncs.com/picbed/markdown/20221004164223.png)  


Open the example script `so_ech.m` in `script` folder. Install [the MATLAB toolbox `FieldTrip`](https://www.fieldtriptoolbox.org/) as the tip unless installed already. Note that just add the installation root directory to MATLAB path instead of all subfolders. Then call `ft_defaults` to install the toolbox in your MATLAB environment as mentioned.  
```matlab
%% Install the Fieldtrip
% If you don't have FieldTrip installed, download Fieldtrip. Then uncomment
% the next few lines to active the tool box, remember to rewrite the path
% of Fieldtrip installed. 

dn.ft = 'D:\Softwares\MATLAB\Codes\packages\fieldtrip\fieldtrip-20220104\fieldtrip-20220104';
addpath(dn.ft);
ft_defaults;
```
Finally you can get the result figure named `ech.pdf` in `data` folder.  
![20221004170309](https://puzzle-li.oss-cn-shanghai.aliyuncs.com/picbed/markdown/20221004170309.png)  

The core function `plotsoech` is programmed as the paper mentioned above. All parameters were defined as done in the paper. Or you can redefine them in "Name-Value" format of MATLAB functions like this:  
```matlab
plotsoech(dn,'dsfreq',150);
```
All parameters you can redefine are listed as follow:  
Parameter name|Description|Default value
---|---|---
`lpcutoff`|Low-pass filtering is performed on the data before and after downsampling respectively, and the first and two elements of the vector represent the cutoff frequencies (Hz) of the two filterings respectively.|`[30 3.5]`
`dsfreq`|Low sampling rate (Hz) is required to calculate ECH.|`100`
`ampfold`|An oscillation with an amplitude greater than `ampfold` times the average of all amplitudes is considered as a SO.|`1.25`
`npfold`|An oscillation with a negative peak value greater than `npfold` times the average of all negative peak value is considered as a SO. |`1.25`
`durlim`|An oscillation with a duration limited in `durlim` (seconds) is considered as a SO.|`[0.9 2]`
`toi`|ECH time of interest (seconds). |`[-2 4]`
`binwidth`|ECH bin width (seconds). |`0.05`

The other function `StimShamIdxReader.m` is used to transform the log in `.bin` files to indices in time sample points of EEG signals, developed by Guannan Xi worked in Quanlan.  