--[[
th -e "require'ohnn.temp_lookuptable2_timming'"
--]]
require'cunn'
require'cudnn'
require'ohnn'

V = 30000 + 1 -- vocabulary size
C = 500
M = 80 -- seq length
p = 1
B = 100 -- #batches
padVocabInd = 1
MP = M * p

--V = 30000 + 1 -- vocabulary size
--C = 500
--M = 500 -- seq length
--p = 1
--B = 100 -- #batches
--padVocabInd = 1
--MP = M * p

nloop = 3

-- onehot input
input = torch.LongTensor(B, MP):random(V):cuda()
weight = torch.CudaTensor(V, C):normal()

function timing_module(input, m)
    local time

    -- fprop
    m:forward(input) -- warm up
    time = torch.tic()
    for i = 1, nloop do
        m:forward(input)
    end
    cutorch.synchronize()
    time = torch.toc(time)
    print(torch.type(m) .. ' fprop time ' .. time/nloop)

end

-- lookuptable
m1 = nn.LookupTable(V, C):cuda()
m1.weight:copy(weight)
m1:setPadding(padVocabInd)
print('lookuptable')
--print(m)
timing_module(input, m1)
output1 = m1:forward(input)

-- lookuptable2
m2 = ohnn.LookupTable2(V,C):cuda()
m2.weight:copy(weight)
m2:setPadding(padVocabInd)
print('ohnn.lookuptable2')
timing_module(input, m2)
output2 = m2:forward(input)

-- verify?
function calc_diff(a, b)
    local c = a:view(-1) - b:view(-1)
    return c:abs():max()
end
d = calc_diff(output1, output2)
print( ('diff = %f'):format(d) )
