classdef DynamicTableTest < tests.system.RoundTripTest & tests.system.AmendTest
    methods
        function addContainer(~, file)
            colnames = {'start_time', 'stop_time', 'randomvalues', ...
                'random_multi', 'stringdata', 'compound_table', 'compound_struct', 'logical_data'};
            %add trailing nulls to columnames
            for c =1:length(colnames)
                colnames{c} = char([double(colnames{c}) zeros(1,randi(10))]);
            end

            nrows = 20;
            ids = primes(100)';

            random_multi_vec = types.hdmf_common.VectorData(...
                'description', 'Test multi-dimensional appending using data pipes.', ...
                'data', types.untyped.DataPipe(...
                'axis', 1, ...
                'maxSize', [inf 3 2], ...
                'dataType', 'double'));
            file.intervals_trials = types.core.TimeIntervals(...
                'description', 'test dynamic table column', ...
                'colnames', colnames, ...
                'random_multi', random_multi_vec);
            for iRow = 1:nrows
                file.intervals_trials.addRow(...
                    'start_time', iRow, ...
                    'stop_time', iRow, ...
                    'randomvalues', {rand(2,3),rand(2,5)}, ...
                    'random_multi', rand(1,3,2), ...
                    'stringdata', {'TRUE'}, ...
                    'id', ids(iRow), ...
                    'compound_table', table(rand(1), rand(1), 'VariableNames', {'a', 'b'}), ...
                    'compound_struct', struct('a', rand(), 'b', rand()), ...
                    'logical_data', true);
            end
        end

        function addContainerUnevenColumns(~, file)
            % create and add a container with columns of unmatched length
            colnames = {'start_time', 'stop_time', 'randomvalues'};
            file.intervals_trials = types.core.TimeIntervals(...
                'description', 'test dynamic table column',...
                'colnames', colnames, ...
                'start_time',  types.hdmf_common.VectorData( ...
                'description', 'start time column', ...
                'data', (1:5)' ...
                ), ...
                'stop_time',  types.hdmf_common.VectorData( ...
                'description', 'stop time column', ...
                'data', (2:11)' ...
                ), ...
                'randomvalues',  types.hdmf_common.VectorData( ...
                'description', 'randomvalues column', ...
                'data', mat2cell(rand(25,2), repmat(5, 5, 1)) ...
                ) ...
                );
        end

        function addContainerUnmatchedIDs(~, file)
            % create and add a container with columns of unmatched length
            colnames = {'start_time', 'stop_time', 'randomvalues'};
            file.intervals_trials = types.core.TimeIntervals(...
                'description', 'test dynamic table column',...
                'id',  types.hdmf_common.ElementIdentifiers( ...
                'data', (0:2)' ...
                ), ...
                'colnames', colnames, ...
                'start_time',  types.hdmf_common.VectorData( ...
                'description', 'start time column', ...
                'data', (1:5)' ...
                ), ...
                'stop_time',  types.hdmf_common.VectorData( ...
                'description', 'stop time column', ...
                'data', (2:6)' ...
                ), ...
                'randomvalues',  types.hdmf_common.VectorData( ...
                'description', 'randomvalues column', ...
                'data', mat2cell(rand(25,2), repmat(5, 5, 1)) ...
                ) ...
                );
        end
        
        function addContainerUndefinedIDs(~, file)
            % create and add a container with undefined id field
            colnames = {'start_time', 'stop_time', 'randomvalues'};
            file.intervals_trials = types.core.TimeIntervals(...
                'description', 'test dynamic table column',...
                'colnames', colnames, ...
                'start_time',  types.hdmf_common.VectorData( ...
                'description', 'start time column', ...
                'data', (1:5)' ...
                ), ...
                'stop_time',  types.hdmf_common.VectorData( ...
                'description', 'stop time column', ...
                'data', (2:6)' ...
                ), ...
                'randomvalues',  types.hdmf_common.VectorData( ...
                'description', 'randomvalues column', ...
                'data', mat2cell(rand(25,2), repmat(5, 5, 1)) ...
                ) ...
                );
        end

        function c = getContainer(~, file)
            c = file.intervals_trials.vectordata.get('randomvalues');
        end

        function appendContainer(testCase, file)
            container = testCase.getContainer(file);
            container.data = rand(size(container.data)); % new random values.
            file.intervals_trials.vectordata.get('stringdata').data = repmat({'FALSE'}, 20, 1);
            %test adding new column with argument
            file.intervals_trials.addColumn( ...
                'newcolumn', types.hdmf_common.VectorData( ...
                'description', 'newly added column', ...
                'data', (20:-1:1) .' ...
                ) ...
                );
            % verify error is thrown when addRow input is MATLAB table
            t = table( ...
                (1:2:40)', (1:4:80)' , ...
                'VariableNames', {'newcolumn2', 'newcolumn3'} ...
                );
            testCase.verifyError(@() file.intervals_trials.addColumn(t), ...
                "NWB:DynamicTable" ...
                );
        end

        function appendRaggedContainer(~, file)
            % create synthetic data
            data = (100:-1:1);
            break_ind = [sort(randperm(99,19)) 100];
            dataArray = cell(1,length(break_ind));
            startInd = 1;
            for i = 1:length(break_ind)
                endInd = break_ind(i);
                dataArray{i} = data(startInd:endInd);
                startInd = endInd+1;
            end
            % get corresponding VectorData and VectorIndex
            [rag_col, rag_col_index] = util.create_indexed_column(dataArray);
            % append ragged column
            file.intervals_trials.addColumn( ...
                'newraggedcolumn',rag_col, ...
                'newraggedcolumn_index',rag_col_index ...
                )
        end
    end

    methods (Test)
        function getRowTest(testCase)
            Table = testCase.file.intervals_trials;

            BaseVectorData = Table.vectordata.get('randomvalues');
            VectorDataInd = Table.vectordata.get('randomvalues_index');
            VectorDataIndInd = Table.vectordata.get('randomvalues_index_index');

            endInd = VectorDataIndInd.data(5);
            startInd = VectorDataIndInd.data(4) + 1;

            Indices = startInd:endInd;
            dataIndices = cell(length(Indices),1);
            for iRaggedInd = 1:length(Indices)
                endInd = VectorDataInd.data(Indices(iRaggedInd));
                if 1 == Indices(iRaggedInd)
                    startInd = 1;
                else
                    startInd = VectorDataInd.data(Indices(iRaggedInd) - 1) + 1;
                end
                dataIndices{iRaggedInd} = BaseVectorData.data(:, (startInd:endInd) .');
            end

            actualData = Table.getRow(5, 'columns', {'randomvalues'});
            testCase.verifyEqual(dataIndices, actualData.randomvalues{1});

            % test with appended ragged columns
            testCase.appendRaggedContainer(testCase.file)
            Table = testCase.file.intervals_trials;
            % retrieve ragged column and index
            BaseVectorData = Table.vectordata.get('newraggedcolumn');
            VectorDataInd = Table.vectordata.get('newraggedcolumn_index');
            % verify end of ragged column index equal length of data vector
            testCase.verifyEqual(length(BaseVectorData.data),double(VectorDataInd.data(end)))
            % get expected ragged data
            endInd = VectorDataInd.data(10);
            startInd = VectorDataInd.data(9) + 1;
            expectedData = BaseVectorData.data(startInd:endInd);
            % get actual ragged data
            actualData = Table.getRow(10);
            % compare
            testCase.verifyEqual(expectedData,actualData.newraggedcolumn{1})
        end

        function getRowRoundtripTest(testCase)
            filename = ['MatNWB.' testCase.className() '.testGetRow.nwb'];
            nwbExport(testCase.file, filename);
            ActualFile = nwbRead(filename, 'ignorecache');
            ActualTable = ActualFile.intervals_trials;
            ExpectedTable = testCase.file.intervals_trials;

            % even if struct is passed in. It is still read back as a
            % table. So we cheat a bit here since this is expected a2a.
            CompoundStructVector = ExpectedTable.vectordata.get('compound_data_struct');
            ExpectedCompoundStruct = CompoundStructVector.data;
            CompoundStructVector.data = struct2table(ExpectedCompoundStruct);

            testCase.verifyEqual(ExpectedTable.getRow(5), ActualTable.getRow(5));
            testCase.verifyEqual(ExpectedTable.getRow([5 6]), ActualTable.getRow([5 6]));
            testCase.verifyEqual(ExpectedTable.getRow([13, 19], 'useId', true),...
                ActualTable.getRow([13, 19], 'useId', true));
        end

        function toTableTest(testCase)
            % test DynamicTable toTable method.
            % 1. For a generic table, the toTable output should be very
            % similar to getRow output (except for presence of id column)
            %
            % retrieve rows from dynamic table
            ExpectedSubTable = testCase.file.intervals_trials.getRow(1:20);
            % convert DynamicTable to MATLAB table
            TrialsTable = testCase.file.intervals_trials.toTable();
            TrialsTable.id = []; %remove id column
            % retrieve rows from MATLAB table
            ActualSubTable = TrialsTable(1:20,:);
            % compare
            testCase.verifyEqual(ExpectedSubTable,ActualSubTable)
            % 2. For a table with a DynamicTable regions, the toTable output
            % with false index argument should return the rows of the
            % target DynamicTable.
            %
            % create table with DynamicTableRegion
            DTRCol = types.hdmf_common.DynamicTableRegion( ...
                'description', 'references rows of another table', ...
                'data', randi([0 9],10,1), ...  # 0-indexed
                'table',types.untyped.ObjectView(testCase.file.intervals_trials) ...  %
                );
            DataCol = types.hdmf_common.VectorData( ...
                'description', 'data column', ...
                'data', (1:10)' ...
                );
            DTRTable = types.hdmf_common.DynamicTable( ...
                'description', 'test table with DynamicTableRegion', ...
                'colnames', {'dtr_col','data_col'}, ...
                'dtr_col', DTRCol, ...
                'data_col',DataCol, ...
                'id', types.hdmf_common.ElementIdentifiers( ...
                'data', (0:9)' ...
                ) ...
                );
            % convert DynamicTable to MATLAB table
            TrialsTableNoIndex = DTRTable.toTable(false);% include actual rows
            TrialsTableIndex = DTRTable.toTable(true);% include only index of rows
            % verify that the row included in DynamicTable and the
            % actual row indicated by the DynamicTableRegion are the same
            for i = 1:10
                testCase.verifyEqual( ...
                    testCase.file.intervals_trials.getRow( ...
                    TrialsTableIndex.dtr_col(i)+1 ... % must add 1 because DynamicTableRegion uses 0-indexing
                    ), ...
                    TrialsTableNoIndex.dtr_col{i} ...
                    );
            end
        end

        function DynamicTableCheckTest(testCase)
            % Verify that the checkConfig utility function
            % throws error when defining an invalid table
            %
            % 1. Defining a table with columns of unmatched length
            testCase.verifyError( ...
                @() testCase.addContainerUnevenColumns(testCase.file), ...
                'NWB:DynamicTable:CheckConfig:InvalidShape' ...
                )
            % 2. Defining a table with length of id's does not match
            % the number of columns
            testCase.verifyError( ...
                @() testCase.addContainerUnmatchedIDs(testCase.file), ...
                'NWB:DynamicTable:CheckConfig:InvalidId' ...
                )
            %3. Defining a table with unspecified IDs
            testCase.addContainerUndefinedIDs(testCase.file)
            Table = testCase.file.intervals_trials;
            % verify created IDs of same length as columns
            expectedLength = length(Table.start_time.data);
            actualLength = length(Table.id.data);
            testCase.verifyEqual(expectedLength, actualLength)
        end

        function testEmptyTable(testCase)
            % validate that empty colnames should work if the number of
            % columns agree. (Yes, id is not considered a column so the
            % height of the dynamic table is still 3 but with zero
            % columns).
            types.core.TimeIntervals(...
                'description', 'test dynamic table column',...
                'id',  types.hdmf_common.ElementIdentifiers('data', (0:2)'));

            % validate that properties checking works (start_time is a
            % property of TimeIntervals)
            testCase.verifyError(@()types.core.TimeIntervals(...
                'description', 'test error', ...
                'start_time', types.hdmf_common.VectorData( ...
                'description', 'start time column', ...
                'data', (1:5)' ...
                )), ...
                'NWB:DynamicTable:CheckConfig:ColumnNamesMismatch');

            % validate that "vectordata" set checking works.
            testCase.verifyError(@()types.core.TimeIntervals(...
                'description', 'test error', ...
                'randomvalues', types.hdmf_common.VectorData( ...
                'description', 'random values', ...
                'data', mat2cell(rand(25,2), repmat(5, 5, 1)))), ...
                'NWB:DynamicTable:CheckConfig:ColumnNamesMismatch');
        end
    end
end

function zipped = zipArrays(A,B)
zipped = zeros((length(A)+length(B)),1);
countA = 1;
countB = 1;
for i = 1:length(A)+length(B)
    if mod(i,2)
        zipped(i) = A(countA);
        countA = countA+1;
    else
        zipped(i) = B(countB);
        countB = countB+1;
    end
end
end
