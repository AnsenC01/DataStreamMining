function testdictionaryargument
%��ȡͨ���ֵ�
%  ��ȫ��������ѵ���ֵ�
%  �ֵ�ѵ������KSVDѵ������
%  �ֵ�ԭ�ӵ�ѡ�����Batch-OMP�㷨
%  ѵ�����õ��ֵ�Ϊ�������ֵ�
%  ���ksvd

%  B506
%  Computer Science School
%  Wuhan University, Wuhan 430072 China
%  zhujiahui@whu.edu.cn
%  2013-12-08

disp(' ');
disp('  **********  ��ȡͨ���ֵ�  **********');
disp(' ');

%% ��д�ļ�Ŀ¼ %%

%read_filename = 'dataset/general_ksvd/topics_data2/ѵ������.txt';
read_filename = 'dataset/general_ksvd/Music5/ѵ������.txt';

%write_directory = 'dataset/non_orthogonal/topics_data2/800';
write_directory = 'dataset/non_orthogonal/Music5/3500';

if ~isdir(write_directory)
    mkdir(write_directory);
end

% ѵ������
global_data = load(read_filename);
printf('���ݶ�ȡ���\n');

tic;
%% KSVDѵ������ %%
params.data = global_data;  % ѵ������
%params.Tdata = 20;  % ����΢������ϡ���
params.Tdata = 25;  % Ӣ������ѷ����ϡ���
params.dictsize = 3500;  % �ֵ�ԭ�Ӹ���
params.iternum = 30;  % KSVDѵ����������
params.memusage = 'high';  % �ڴ�ʹ��Ϊ�߼�״̬�Ϻ�

printf('����ѵ������ȴ�\n');

% KSVD�ֵ�ѵ��
[Dksvd, g, err] = ksvd(params, '');

time1 = toc;
printf('\nѵ���ֵ���ϣ�����ʱ%f��\n', time1);

%% ���չʾ %%
final_error = err(length(err));  % ���������в�
printf('\n������%f\n', final_error);
figure;
plot(err);
title('K-SVD error convergence');
xlabel('Iteration'); ylabel('RMSE');

printf('\n�ֵ��С %d * %d', size(global_data, 1), params.dictsize);
printf('���ݸ���: %d\n', size(global_data, 2));

tic;
%% д���ļ� %%

write_filename1 = strcat(write_directory, '/�ֵ�.txt');
dlmwrite(write_filename1, Dksvd, ' ');

write_filename2 = strcat(write_directory, '/ϡ��ϵ��.txt');
dlmwrite_each_line(write_filename2, g);

write_filename3 = strcat(write_directory, '/RMSE.xlsx');
xlswrite(write_filename3, err);

time2 = toc;
printf('д���ļ���ʱ%f��', time2);


end

function dlmwrite_each_line(write_filename, X)
row = size(X, 1);
for i = 1 : row
    dlmwrite(write_filename, full(X(i, :)), '-append', 'delimiter', ' ')
end
end