function compressquery

%�ڽ�������ѹ�����ݽ��в�ѯ

%  B506
%  Computer Science School
%  Wuhan University, Wuhan 430072 China
%  zhujiahui@whu.edu.cn
%  2013-12-14

%% ��д�ļ�Ŀ¼ %%
tic;

% ѹ���Ķ���Ϊ�źź�ʱ����Ϣ��
% ��ѯ������Ϊʱ��͹ؼ���
read_directory1 = 'dataset/pyramid/topics_data1/data';
read_directory2 = 'dataset/pyramid/topics_data1/id_time';
read_directory3 = 'dataset/pyramid/topics_data1/original_index';

write_directory1 = 'dataset/pyramid/topics_data1/data';
write_directory2 = 'dataset/pyramid/topics_data1/id_time';
write_directory3 = 'dataset/pyramid/topics_data1/original_index';

if ~isdir(write_directory1)
    mkdir(write_directory1);
end
if ~isdir(write_directory2)
    mkdir(write_directory2);
end
if ~isdir(write_directory3)
    mkdir(write_directory3);
end

keyword_list = {'��', '��һ'};
mode = 'AND';
time_interval = {'2013-7-1', '2013-7-5'};
time_interval2 = query_time_format(time_interval);
select = 30;

write_filename = write_directory + u'/q2.txt'

read_filename1 = 'dataset/non_orthogonal/topics_data1/Q.txt';
Q = load(read_filename1);

% ��ѹ����������Ƭ��
data_files = dir(fullfile(read_directory2, '*.txt'));

% ѡ�����ع�������Ƭ
% ��ȡʱ����Ϣ
for i = 1 : length(data_files)
    id_time = load(strcat(strcat(read_directory2, '/'), strcat(num2str(i), '.txt')));
    time_lines = id_time(:, 2);

    % ��ǰƬ������ʱ��Ȳ�ѯ�趨�Ŀ�ʼʱ�仹�磬��������Ƭ
    if time_lines(end) < time_interval2(1)
         continue;
    %��ǰƬ������ʱ��Ȳ�ѯ�趨�Ľ���ʱ���������
    elseif time_lines(1) > time_interval2(2)
          break;
    else
        % ѹ������������Ӧԭʼ���ݵ�����
        % ÿһ������Ƭ�����б���
        for j = 1 : length(time_lines)
            % ��ǰ����ʱ��ʱ��
                now_t = float(time_lines[j].strip().split()[-1])
                
                if (now_t >= start) and (now_t <= end) and (j in data_index):
                    if mode == "OR":
                        flag = 0
                        for each1 in keyword_list:
                            for k in range(len(word_list)):
                                if (each1 in word_list[k]) and (float(each_weibo_vsm[j][k]) > 0.000001):
                                    this_message = " ".join(vsm_map_word(each_weibo_vsm[j], word_list))
                                    if this_message not in query_result:
                                        query_result.append(this_message)
                                        entropy_result.append(entropy_list[j])
                                    flag = 1
                                    break
                            if flag == 1:
                                break
                    else:
                        flag = 0
                        for each1 in keyword_list:
                            for k in range(len(word_list)):
                                if (each1 in word_list[k]) and (float(each_weibo_vsm[j][k]) > 0.000001):
                                    flag += 1
                                    break
                                
                        if flag == len(keyword_list):
                            this_message = " ".join(vsm_map_word(each_weibo_vsm[j], word_list))
                            if this_message not in query_result:
                                query_result.append(this_message)
                                entropy_result.append(entropy_list[j])
            

% ����������ѹ������
if length(data_files) < 2
    compress_index = cell({1});
    fprintf('����Ƭ�� < 2������ѹ��');
else
    compress_index = pyramid_index(length(data_files));
    
    % ����ÿһ�㴰�ڵĴ�С
    gram = 4096;  % ����΢������Ϊ2 * 2048

    % ѭ������������������ÿһ��
    for i = 1 : length(compress_index)
        
        fprintf('����ѹ����%d������\n', i);
        % ����ѹ���Ĺ���ѡ��ò��ÿ������Ƭ����Ϣ����
        select = gram / length(compress_index{i});    
        
        % ÿһ�����������Ƭѹ���������
        data_level_result = zeros(120, gram);
        
        % ѹ����ʱ����Ϣ��
        id_level_result = cell(gram, 1);
        time_level_result = cell(gram, 1);

        column_count = 1;
        
        % ����ÿһ���ÿһ������Ƭ���
        for j = 1 : length(compress_index{i})
            
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
                
                column_count = column_count + 1;
            end
            
        end
        
        % һ�������󣬽��ò����������Ƭѹ���������д���ļ�
        % д���ÿһ�д���һ����Ϣ��δѹ���Ĳ�������Ҳ��ÿһ�д���һ����Ϣ��
        dlmwrite(strcat(strcat(write_directory1, '/'), strcat(num2str(i), '.txt')), full(data_level_result), ' ');
         % ���ò���������ݵ�ʱ����Ϣ��д���ļ�
        write_it_to_text(strcat(strcat(write_directory2, '/'), strcat(num2str(i), '.txt')),  id_level_result,  time_level_result);

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
function result_time = query_time_format(time_interval)

%2013-01-01----41275
    
result_time = zeros(1, 2);
base_time = datenum('2013-1-1');
base_number = 41274;

for i = 1 : length(time_interval)
    first_time = datenum(time_interval{i});
    result_time{i} = base_number + first_time - base_time;
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