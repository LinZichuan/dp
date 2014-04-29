------------------------------------------------------------------------
--[[ SentenceSet ]]--
-- Inherits DataSet
-- Used for Language Modeling
-- Takes a sequence of words stored as a tensor of word ids,
-- and a tensor holding the start index of the sentence of its 
-- commensurate word id (the one at the same index).
-- Unlike DataSet, for memory efficiency reasons, 
-- this class does not store its data in BaseTensors.
-- However, the outputs of batch(), sub(), index() are dp.Batches
-- containing WordTensors (inputs) and ClassTensors (targets).
------------------------------------------------------------------------
local SentenceSet, parent = torch.class("dp.SentenceSet", "dp.DataSet")
SentenceSet.isSentenceSet = true

function SentenceSet:__init(config)
   assert(type(config) == 'table', "Constructor requires key-value arguments")
   local args, which_set, data, context_size, end_id, start_id 
      = xlua.unpack(
      {config},
      'SentenceSet', 
      'Stores a sequence of sentences. Each sentence is a sequence '..
      'words. Each word is represented as an integer.',
      {arg='which_set', type='string',
       help='"train", "valid" or "test" set'},
      {arg='data', type='torch.Tensor', 
       help='A torch.tensor with 2 columns. First col is for storing '..
       'start indices of sentences. Second col is for storing the '..
       'sequence of words as shuffled sentences. Sentences are '..
       'only seperated by the sentence_end delimiter.', req=true},
      {arg='context_size', type='number', req=true,
       help='number of previous words to be used to predict the next.'},
      {arg='end_id', type='number', req=true,
       help='word_id of the sentence end delimiter : "</S>"'}
      {arg='start_id', type='number', req=true,
       help='word_id of the sentence start delimiter : "<S>"'}
   )
   self:setWhichSet(which_set)
   self._data = data
   self._context_size = context_size
   self._start_id = start_id
   self._end_id = end_id
end

function SentenceSet:setInputs(inputs)
   error"Not Implemented"
end

function SentenceSet:setTargets(targets)
   error"Not Implemented"
end

function SentenceSet:inputs()
   error"Not Implemented"
end

function SentenceSet:targets()
   error"Not Implemented"
end

-- We assume that preprocessing has already been applied
function SentenceSet:preprocess()
   error"Not Implemented"
end

function SentenceSet:batch(batch_size)
   return dp.Batch{
      which_set=self:whichSet(), epoch_size=self:nSample(),
      inputs=self:inputs():sub(1, batch_size),
      targets=self:targets() and self:targets():sub(1, batch_size)
   }
end

-- TODO add optional batch as first argument (to all BaseSets)
function SentenceSet:sub(start, stop)
   local data = self._data:sub(start, stop)
   local words = self._data:select(2, 2)
   local inputs = torch.IntTensor(data:size(1), self._context_size)
   -- fill tensor with start delimiters : <S>
   inputs:fill(self._start_id)
   local targets = torch.IntTensor(data:size(1))
   for i=1,data:size(1) do
      local sample = data:select(1, i)
      -- add input
      local context = words:narrow(1, sample[1], start+i-1)
      inputs:select(1, i):sub(
         self._context_size-context:size()+1, self._context_size
      ):copy(context)
      -- add target
      targets[i] = sample[2]
   end   
      
   return dp.Batch{
      which_set=self:whichSet(), epoch_size=self:nSample(),
      inputs=inputs, targets=targets
   }   
end

function SentenceSet:index(batch, indices)
   if (not batch) or (not indices) then 
      indices = indices or batch
      return dp.Batch{
         which_set=self:whichSet(), epoch_size=self:nSample(),
         inputs=self:inputs():index(indices),
         targets=self:targets() and self:targets():index(indices)
      }
   end
   assert(batch.isBatch, "Expecting dp.Batch at arg 1")
   self:inputs():index(batch:inputs(), indices)
   if self:targets() then
      self:targets():index(batch:targets(), indices)
   end
   return batch
end
