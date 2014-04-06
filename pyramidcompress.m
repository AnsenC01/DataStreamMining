function pyramidcompress

%���������΢�����ݰ��������ν���ѹ��
%  ѹ���Ķ���Ϊ�źź�ʱ����Ϣ��
%  ����������ԭʼ�����е�������Ϣ

%  B506
%  Computer Science School
%  Wuhan University, Wuhan 430072 China
%  zhujiahui@whu.edu.cn
%  2013-12-14

%% ��д�ļ�Ŀ¼ %%
tic;

% ѹ���Ķ���Ϊ�źź�ʱ����Ϣ��
% ѹ��������Ϊ��Ϣ��ֵ
read_directory1 = 'dataset/non_orthogonal/topics_data1/�����ź�';
read_directory2 = 'D:/Local/workspace/MicroblogDataStreamCompress/dataset/batch_data_segment/topics_data1/entropy';
read_directory3 = 'D:/Local/workspace/MicroblogDataStreamCompress/dataset/batch_data_segment/topics_data1/update_id_time';

write_directory1 = 'dataset/pyramid/topics_data1/data';
write_directory2 = 'dataset/pyramid/topics_data1/id_time';
write_directory3 = 'dataset/pyramid/topics_data1/original_index';
write_directory4 = 'dataset/pyramid/topics_data1/entropy';

if ~isdir(write_directory1)
    mkdir(write_directory1);
end
if ~isdir(write_directory2)
    mkdir(write_directory2);
end
if ~isdir(write_directory3)
    mkdir(write_directory3);
end
if ~isdir(write_directory4)
    mkdir(write_directory4);
end

% ��ѹ����������Ƭ��
data_files = dir(fullfile(read_directory1, '*.txt'));
%data_files = 100;

% ����������ѹ������
if length(data_files) < 2
    compress_index = cell({1});
    fprintf('����Ƭ�� < 2������ѹ��');
else
    compress_index = pyramid_index(length(data_files));
    %compress_index = pyramid_index(data_files);
    
    % ����ÿһ�㴰�ڵĴ�С
    gram = 5000;  % ����΢������Ϊ2 * 2500

    % ѭ������������������ÿһ��
    for i = 1 : length(compress_index)
        
        fprintf('����ѹ����%d������\n', i);
        % ����ѹ���Ĺ���ѡ��ò��ÿ������Ƭ����Ϣ����
        each_select = floor(gram / length(compress_index{i}));
        rest_select = gram - each_select * (length(compress_index{i}) - 1);  
        
        % ÿһ�����������Ƭѹ���������
        data_level_result = zeros(120, gram);
        
        % ѹ����ʱ����Ϣ��
        id_level_result = cell(gram, 1);
        time_level_result = cell(gram, 1);
        
        % ÿһ�������������ֵѹ���������
        entropy_level_result = zeros(gram, 1);

        column_count = 1;
        
        % ����ÿһ���ÿһ������Ƭ���
        for j = 1 : length(compress_index{i})
            if j == length(compress_index{i})
                select = rest_select;
            else
                select = each_select;
            end
            
            % ��ȡ��ֵ������������ţ���Ϊ�������������
            entropy = load(strcat(strcat(read_directory2, '/'), strcat(num2str(compress_index{i}(j)), '.txt')));
            line_index = 1 : length(entropy);
            line_index = line_index';
            
            % ����ֵ��������
            el = [entropy, line_index];
            el1 = sortrows(el, -1);
            
            % ѡ��ǰselect���к�����
            % ������������ȷ��ѹ�������Ϣ�����λ�ò���
            update_index = el1(:, 2);
            update_index = sort(update_index(1 : select));
            
            % ѹ��������������ԭ�������е�����λ��
            mix_index = [(compress_index{i}(j) * ones(select, 1)), update_index];
            dlmwrite(strcat(strcat(write_directory3, '/'), strcat(num2str(i), '.txt')), mix_index, '-append', 'delimiter', ' ');
            
            %ע�⣬����Ĳ�������ÿһ�д���һ����Ϣ
            sample_data = load(strcat(strcat(read_directory1, '/'), strcat(num2str(compress_index{i}(j)), '.txt')));
            
            % ע��˴����ַ�������
            fid = fopen(strcat(strcat(read_directory3, '/'), strcat(num2str(compress_index{i}(j)), '.txt')));
            phst = textscan(fid, '%s %s');
            fclose(fid);
            
            % ��ֵ��ѹ�����
            for k = 1 : length(update_index)
                data_level_result(:, column_count) = sample_data(:, update_index(k));
                
                id_level_result(column_count) = phst{1, 1}(update_index(k));
                time_level_result(column_count) = phst{1, 2}(update_index(k));
                
                entropy_level_result(column_count) = entropy(update_index(k), 1);
                
                column_count = column_count + 1;
            end
            
        end
        
        % һ�������󣬽��ò����������Ƭѹ���������д���ļ�
        % д���ÿһ�д���һ����Ϣ��δѹ���Ĳ�������Ҳ��ÿһ�д���һ����Ϣ��
        dlmwrite(strcat(strcat(write_directory1, '/'), strcat(num2str(i), '.txt')), full(data_level_result), ' ');
        % ���ò���������ݵ�ʱ����Ϣ��д���ļ�
        write_it_to_text(strcat(strcat(write_directory2, '/'), strcat(num2str(i), '.txt')),  id_level_result,  time_level_result);
        % ���ò���������ݵ���ֵ��Ϣ��д���ļ�
        dlmwrite(strcat(strcat(write_directory4, '/'), strcat(num2str(i), '.txt')), entropy_level_result, ' ');

        fprintf('��%d������ѹ�����\n', i);
    end
end

fprintf('��������ѹ�����\n');

% ������ѹ������
write_filename = 'dataset/pyramid/topics_data1/pyramid_index.txt';
dlmwrite_cell(write_filename, compress_index);

toc;
end


%% �����ϲ�ѹ��������
function pyramid_all = pyramid_index(batch_number)

% batch_number:�ļ��ܸ���
% ��������ʼ����
level_element = 2;
pyramid_all = cell({[1,2]});

%��2Ƭ����Ϊ��λ����ѹ��
for i = 4 : 2 : batch_number
    flag = 0;
    level = length(pyramid_all);
    
    for j = level - 1 : -1 : 1
        if (length(pyramid_all{j}) < level_element(j))
            %��ĳһ��δ������ϲ�ѹ��
            pyramid_all{j} = [pyramid_all{j}, pyramid_all{j + 1}];
            pyramid_all(j + 1) = [];
            pyramid_all{end + 1} = [i - 1, i];
            flag = 1;
            break;
        end
    end
    
    %�����в���������½�һ��
    if flag == 0
        pyramid_all{end + 1} = [i - 1, i];
        level_element = [2 ^ (level + 1), level_element];
    end
end
end


%% ������ѹ������д���ļ�
function dlmwrite_cell(write_filename, X)
row = length(X);
for i = 1 : row
    dlmwrite(write_filename, full(X{i}), '-append', 'delimiter', ' ')
end
end


%% �ַ���Ԫ������д���ļ� %%
function write_it_to_text(write_filename, id, time)

row = length(id);

fid = fopen(write_filename, 'w+');
for i = 1 : row
    fprintf(fid, '%s %s\n', id{i}, time{i});
end

fclose(fid); 
end