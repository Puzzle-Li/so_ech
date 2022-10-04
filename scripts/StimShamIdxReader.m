function [stim_idx] = StimShamIdxReader(filename)
offset=94;

fid = fopen(filename,'r');
fseek(fid, floor(offset), 'bof');
stim_idx = fread(fid,inf,'uint32')*15;
end

