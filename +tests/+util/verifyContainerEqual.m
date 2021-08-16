function verifyContainerEqual(testCase, actual, expected)
testCase.verifyEqual(class(actual), class(expected));
props = properties(actual);
for i = 1:numel(props)
    prop = props{i};
    actualVal = actual.(prop);
    expectedVal = expected.(prop);
    failmsg = ['Values for property ''' prop ''' are not equal'];
    
    if isa(actualVal, 'types.untyped.DataStub')
        actualVal = actualVal.load();
    end

    if startsWith(class(expectedVal), 'types.') && ~startsWith(class(expectedVal), 'types.untyped')
        tests.util.verifyContainerEqual(testCase, actualVal, expectedVal);
    elseif isa(expectedVal, 'types.untyped.Set')
        tests.util.verifySetEqual(testCase, actualVal, expectedVal, failmsg);
    elseif ischar(expectedVal)
        testCase.verifyEqual(char(actualVal), expectedVal, failmsg);
    elseif isa(expectedVal, 'types.untyped.ObjectView') || isa(expectedVal, 'types.untyped.SoftLink')
        testCase.verifyEqual(actualVal.path, expectedVal.path, failmsg);
    elseif isa(expectedVal, 'types.untyped.RegionView')
        testCase.verifyEqual(actualVal.path, expectedVal.path, failmsg);
        testCase.verifyEqual(actualVal.region, expectedVal.region, failmsg);
    elseif isa(expectedVal, 'types.untyped.Anon')
        testCase.verifyEqual(actualVal.name, expectedVal.name, failmsg);
        tests.util.verifyContainerEqual(testCase, actualVal.value, expectedVal.value);
    elseif isdatetime(expectedVal)...
            || (iscell(expectedVal) && all(cellfun('isclass', expectedVal, 'datetime')))
        % ubuntu MATLAB doesn't appear to propery compare datetimes whereas
        % Windows MATLAB does. This is a workaround to get tests to work
        % while getting close enough to exact date representation.
        actualVal = types.util.checkDtype(prop, 'isodatetime', actualVal);
        if ~iscell(expectedVal)
            actualVal = {actualVal};
            expectedVal = {expectedVal};
        end
        for iDates = 1:length(expectedVal)
           testCase.verifyEqual(...
               convertTo(actualVal{iDates}, 'ntp'),...
               convertTo(expectedVal{iDates}, 'ntp'),...
               failmsg); 
        end
    else
        testCase.verifyEqual(actualVal, expectedVal, failmsg);
    end
end
end