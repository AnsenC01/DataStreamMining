function SVDTransform
%% ���������ֵ�ֽ⣬Ȼ���ع�

%readFilename = 'dataset/TopNWordsTFIDFVSM/��һ����������.txt';
readFilename = 'dataset/TopNWordsTFIDFVSM/����Ѧ����.txt';
X = load(readFilename);  % ��ȡtxt����
disp('Data Load OK!');
selectKeys = 50;

[U, S, V] = svds(X, selectKeys);
clear X;
%S = S(:,1:selectKeys);
%V = V(:,1:selectKeys);
X2 = U * S * V';
X2 = X2';
col = size(X2, 2);  % ԭʼ������������������ĸ���;
row = size(X2, 1);  % ԭʼ���������������ݵ�ά��;
%writeFilename = 'dataset/TopNWordsTFIDFVSM/��һ����������2.txt';
writeFilename = 'dataset/TopNWordsTFIDFVSM/����Ѧ����SVD.txt';
fid = fopen(writeFilename, 'w+');
for i = 1:row
    for j = 1:col
        fprintf(fid, '%f', X2(i,j));
        if j~=col
            fprintf(fid, ' ');
        end
    end
    fprintf(fid, '\n');
end
fclose(fid); 
