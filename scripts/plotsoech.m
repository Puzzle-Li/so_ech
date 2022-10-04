function ax = plotsoech(datadir,prepopt,soopt,echopt)
arguments
    datadir char {mustBeFolder}
    prepopt.lpcutoff (1,2) double = [30 3.5] % Low-pass filtering 
    % is performed on the data before and after downsampling respectively, 
    % and the first and two elements of the vector represent the cutoff 
    % frequencies (Hz) of the two filterings respectively. 
    prepopt.dsfreq double = 100 % Low sampling rate (Hz) is required to 
    % calculate ECH. 
    soopt.ampfold double = 1.25 % An oscillation with an amplitude greater 
    % than 'ampfold' times the average of all amplitudes is considered as a 
    % SO. 
    soopt.npfold double = 1.25 % An oscillation with a negative peak value 
    % greater than 'npfold' times the average of all negative peak value is 
    % considered as a SO. 
    soopt.durlim (1,2) double = [0.9 2] % An oscillation with a duration 
    % limited in 'durlim' (seconds) is considered as a SO. 
    echopt.toi (1,2) double = [-2 4] % ECH time of interest (seconds)..
    echopt.binwidth double = .05 % ECH bin width (seconds). 

end


dn.data = datadir;
condi = {'Stim','Sham'};

for i_condi = 1:length(condi)
    fd = dir(fullfile(dn.data,[condi{i_condi} '*']));
    for i_ses = 1:length(fd)
        dn.ses = fullfile(fd(i_ses).folder,fd(i_ses).name);

        fl = dir(fullfile(dn.ses,'*.edf'));
        fn.edf = fullfile(fl.folder,fl.name);
        [dat,Fs_ori] = prepdata(fn.edf,prepopt);
        Fs = dat.fsample;

        [oseg,indso] = markso(dat,soopt);

        % defined trials in erp data so flag data
        fl = dir(fullfile(dn.ses,'*.bin'));
        fn.bin = fullfile(fl.folder,fl.name);
        toi = echopt.toi;
        trl = segtrl(dat,fn.bin,toi,Fs_ori);

        cfg = [];
        cfg.trl = trl;
        erp = ft_redefinetrial(cfg,dat);

        % count the so
        soflag = dat;
        soflag.trial{1} = zeros(1,length(dat.trial{1}));
        soflag.trial{1}(indso) = 1; 
        soflag = ft_redefinetrial(cfg,soflag);
 
        binwidth = echopt.binwidth; % second
        soo = zeros(length(soflag.trial),(toi(2)-toi(1))/binwidth); % so occurrence (Hz)
        
        for i = 1:length(soflag.trial)
            f = soflag.trial{i};
            soo(i,:) = histcounts(find(f==1),'BinLimits',[0 length(f)-1],'BinWidth',binwidth*Fs);
        end
        soo = mean(soo,1)/binwidth;

        save(fullfile(dn.ses,'erso.mat'),'dat','oseg','trl','erp','soflag','soo','toi');

    end
end

%% Summary the data
soo = cell(1,length(condi));
for i_condi = 1:length(condi)
    fd = dir(fullfile(dn.data,[condi{i_condi} '*']));

    for i_ses = 1:length(fd)
        dn.ses = fullfile(fd(i_ses).folder,fd(i_ses).name);
        mat = load(fullfile(dn.ses,'erso.mat'));
        soo{i_condi}(i_ses,:) = mat.soo;
    end
end
save(fullfile(dn.data,'soo.mat'),'soo');

%% Event correlation histgram
figure; hold on;
cmap = lines(1);
cmap(2,:) = [.6 .6 .6];
for i_condi = 1:length(condi)
    Y = soo{i_condi};
    b{i_condi} = plotech(toi,Y,cmap(i_condi,:));
end
yl = ylim;
line([0 0],[0 yl(2)],'linestyle','--','Color','k');
    
set(gca,'FontSize',8,'YColor','k','XColor','k');
set(gcf,'Units','centimeters', ...
    'Position',[5 5 14 7]);

legend([b{:}],condi);
xlabel('Time (s)');
ylabel('Slow oscillation occurrence (Hz)');
xtl = get(gca,'XTickLabel');
xtl{strcmp(xtl,'0')} = 'Stimuli';
set(gca,'XTickLabel',xtl);
ax = gca;
print(gcf,fullfile(dn.data,'ech'),'-dpdf','-r300');
end

function [dat,Fs_ori] = prepdata(fn,opt)
% data import
cfg = [];
cfg.dataset = fullfile(fn);
dat = ft_preprocessing(cfg);

% low-pass
cfg = [];
cfg.lpfilter = 'yes';
cfg.lpfreq = opt.lpcutoff(1);
cfg.demean = 'yes';
dat = ft_preprocessing(cfg,dat);
Fs_ori = dat.fsample;   % mark the Fs before downsampling

% downsample to 100 Hz
Fs = opt.dsfreq;   % Hz
cfg = [];
cfg.resamplefs = Fs;
dat = ft_resampledata(cfg,dat);

% low-pass
cfg = [];
cfg.lpfilter = 'yes';
cfg.lpfreq = opt.lpcutoff(2);
dat = ft_preprocessing(cfg,dat);
end

function b = plotech(toi,Y,cmap)
    n = size(Y,1);
    y = mean(Y,1);
    e = std(Y,1) / n.^.5;
    t = linspace(toi(1),toi(2),length(y)+1);
    w = t(2)-t(1);
    x = w/2 + t(1:end-1);
    b = bar(x,y,1,'FaceAlpha',0.5,'EdgeColor',cmap,'FaceColor',cmap);
    xlim([t(1) t(end)])
    for i = 1:length(e)
        if e(i) ~= 0
            line([x(i) x(i)],[y(i) y(i)+e(i)],'Color',cmap);
            line([x(i)-.2*w x(i)+.2*w],[y(i)+e(i) y(i)+e(i)],'Color',cmap);
        end
    end
end

function [oseg,indso] = markso(dat,opt)
data = dat.trial{1};
Fs = dat.fsample;
indtermi = find([0 diff(sign(data))] < 0);  % ind of terminals
oseg = struct;

for i = 1:length(indtermi)-1
    oseg(i).data = data(indtermi(i):indtermi(i+1)-1);
    oseg(i).on = indtermi(i);
    oseg(i).off = indtermi(i+1)-1;
    oseg(i).isso = false;

    [oseg(i).pp,indpp] = findpeaks(oseg(i).data);
    [oseg(i).np,indnp] = findpeaks(-oseg(i).data);   % equal to abs of negtive peak value
    oseg(i).indpp = indpp + oseg(i).on - 1;
    oseg(i).indnp = indnp + oseg(i).off - 1;

    if all([length(oseg(i).pp) length(oseg(i).np)] == 1)
        oseg(i).amp = max(oseg(i).pp) + max(oseg(i).np);
        if length(oseg(i).data)/Fs<=opt.durlim(2) && length(oseg(i).data)/Fs>=opt.durlim(1)
            oseg(i).isso = true;
        end
    end
    
end

ampthr = opt.ampfold * mean([oseg([oseg(:).isso]).amp]);
npthr = opt.npfold * mean([oseg([oseg(:).isso]).np]);
for i = find([oseg(:).isso])
    if oseg(i).amp < ampthr || oseg(i).np < npthr
        oseg(i).isso = false;
    end
end
indso = [oseg([oseg(:).isso]).indnp];

end

function trl = segtrl(dat,fn,toi,Fs_ori)
Fs = dat.fsample;
dsr = Fs_ori / Fs;

ind = StimShamIdxReader(fn);
ind = floor(ind/dsr);

begsample = ind + toi(1)*Fs;
endsample = ind + toi(2)*Fs;
offset = ind;
trl = [begsample endsample offset];
end