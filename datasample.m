function datasample
%% ��д�ļ�Ŀ¼ %%

read_directory1 = 'D:/Local/workspace/MicroblogDataStreamCompress/dataset/batch_data_segment/topics_data2/update_vsm';
%read_directory1 = 'D:/Local/workspace/MicroblogDataStreamCompress/dataset/batch_data_segment/Music/Music2/update_vsm';

write_directory = 'dataset/non_orthogonal/topics_data2';
write_directory2 = 'dataset/non_orthogonal/topics_data2/�����ź�';
%write_directory = 'dataset/non_orthogonal/Music2';
%write_directory2 = 'dataset/non_orthogonal/Music2/�����ź�';

write_filename1 = 'dataset/non_orthogonal/topics_data2/Q.txt';
%write_filename1 = 'dataset/non_orthogonal/Music2/Q.txt';

if ~isdir(write_directory)
    mkdir(write_directory);
end
if ~isdir(write_directory2)
    mkdir(write_directory2);
end

data_files = dir(fullfile(read_directory1, '*.txt'));
sample_time = zeros(length(data_files), 1);

tic;
% ����ȡ��ǰĿ¼�µ�һ���ļ�
data_first = load(strcat(read_directory1, '/1.txt'));

M_sample = 120;  % ����΢������ά��
%M_sample = 250;  % ����ѷ����ά��
L = size(data_first, 2);  % ԭʼ����ά��
Q = normrnd(1, sqrt(1 / sqrt(M_sample)), M_sample, L);  % ��˹�������
fprintf('���������ά�ȣ�%d * %d\n', size(Q, 1), size(Q, 2));
base_time = toc;

dlmwrite(write_filename1, full(Q), ' ');  % д���ļ�

for i = 1 : length(data_files)
    data = load(strcat(strcat(read_directory1, '/'), strcat(num2str(i), '.txt')));
    fprintf('���ڴ����%dƬ����\n', i);
    
    tic;
    data1 = Q * data';
    this_time = toc;
    sample_time(i, 1) = base_time + this_time;
    
    fprintf('���ݲ������ά�ȣ�%d * %d\n', size(data1, 1), size(data1, 2));
    
    % ��д���ļ��д��󣬻�������ϡ��ģ���ʹ��full(data1)
    dlmwrite(strcat(strcat(write_directory2, '/'), strcat(num2str(i), '.txt')), data1, ' ');
    fprintf('��%dƬ���ݴ������\n\n', i);
end

write_filename = strcat(write_directory, '/����ʱ��.xlsx');
xlswrite(write_filename, sample_time);

end
