

%if loading excel file
% filename = 'C:\Users\csmov\OneDrive\Desktop\RPV_standards_schema.xlsx'
% sheet='standardset03302022'
%  
% schema = xlsread(filename,sheet); %how to load txt?


%if loading mat file

%if creating in session
analyteList = inputdlg('Enter list of analytes, separated by spaces');
analyteList = strsplit(char(analyteList));
peak_labels = ['a' 'b' 'c'];
f = figure;
data = zeros(length(peak_labels),length(analyteList));
schema = uitable(f,'Data',data);
schema.RowName = strsplit(peak_labels);
schema.ColumnName = analyteList;
schema.ColumnEditable = true;
set(schema, 'CellEditCallback', 'assignin(''base'',''data2workspace'',get(schema, ''Data''))');

waitfor(gcf);

schema = data2workspace;