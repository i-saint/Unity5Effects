using UnityEngine;
using System.Collections;


namespace Ist
{
    public class MPGPGPUSort
    {
        public struct KIP
        {
            public uint key;
            public uint index;
        }
        public struct SortCB
        {
            public uint level;
            public uint levelMask;
            public uint width;
            public uint height;
        }
    
        ComputeShader m_cs_bitonic_sort;
        ComputeBuffer[] m_buf_consts = new ComputeBuffer[2];
        ComputeBuffer[] m_buf_dummies = new ComputeBuffer[2];
        SortCB[] m_consts = new SortCB[1];
    
        public void Initialize(ComputeShader sh_bitonic_sort)
        {
            m_cs_bitonic_sort = sh_bitonic_sort;
            m_buf_consts[0] = new ComputeBuffer(1, 16);
            m_buf_consts[1] = new ComputeBuffer(1, 16);
            m_buf_dummies[0] = new ComputeBuffer(1, 16);
            m_buf_dummies[1] = new ComputeBuffer(1, 16);
        }
    
        public void Release()
        {
            m_buf_dummies[0].Release();
            m_buf_dummies[1].Release();
            m_buf_consts[0].Release();
            m_buf_consts[1].Release();
        }
    
        public void BitonicSort(ComputeBuffer kip, ComputeBuffer kip_tmp, uint num)
        {
            uint BITONIC_BLOCK_SIZE = 512;
            uint TRANSPOSE_BLOCK_SIZE = 16;
            uint NUM_ELEMENTS = num;
            uint MATRIX_WIDTH = BITONIC_BLOCK_SIZE;
            uint MATRIX_HEIGHT = NUM_ELEMENTS / BITONIC_BLOCK_SIZE;
    
            for (uint level = 2; level <= BITONIC_BLOCK_SIZE; level <<= 1)
            {
                m_consts[0].level = level;
                m_consts[0].levelMask = level;
                m_consts[0].width = MATRIX_HEIGHT; // not a mistake!
                m_consts[0].height = MATRIX_WIDTH; // 
                m_buf_consts[0].SetData(m_consts);
    
                m_cs_bitonic_sort.SetBuffer(0, "consts", m_buf_consts[0]);
                m_cs_bitonic_sort.SetBuffer(0, "kip_rw", kip);
                m_cs_bitonic_sort.Dispatch(0, (int)(NUM_ELEMENTS / BITONIC_BLOCK_SIZE), 1, 1);
            }
    
            // Then sort the rows and columns for the levels > than the block size
            // Transpose. Sort the Columns. Transpose. Sort the Rows.
            for (uint level = (BITONIC_BLOCK_SIZE << 1); level <= NUM_ELEMENTS; level <<= 1)
            {
                m_consts[0].level = (level / BITONIC_BLOCK_SIZE);
                m_consts[0].levelMask = (level & ~NUM_ELEMENTS) / BITONIC_BLOCK_SIZE;
                m_consts[0].width = MATRIX_WIDTH;
                m_consts[0].height = MATRIX_HEIGHT;
                m_buf_consts[0].SetData(m_consts);
    
                // Transpose the data from buffer 1 into buffer 2
                m_cs_bitonic_sort.SetBuffer(1, "consts", m_buf_consts[0]);
                m_cs_bitonic_sort.SetBuffer(1, "kip", kip);
                m_cs_bitonic_sort.SetBuffer(1, "kip_rw", kip_tmp);
                m_cs_bitonic_sort.Dispatch(1, (int)(MATRIX_WIDTH / TRANSPOSE_BLOCK_SIZE), (int)(MATRIX_HEIGHT / TRANSPOSE_BLOCK_SIZE), 1);
    
                // Sort the transposed column data
                m_cs_bitonic_sort.SetBuffer(0, "consts", m_buf_consts[0]);
                m_cs_bitonic_sort.SetBuffer(0, "kip_rw", kip_tmp);
                m_cs_bitonic_sort.Dispatch(0, (int)(NUM_ELEMENTS / BITONIC_BLOCK_SIZE), 1, 1);
    
    
                m_consts[0].level = BITONIC_BLOCK_SIZE;
                m_consts[0].levelMask = level;
                m_consts[0].width = MATRIX_HEIGHT;
                m_consts[0].height = MATRIX_WIDTH;
                m_buf_consts[0].SetData(m_consts);
    
                // Transpose the data from buffer 2 back into buffer 1
                m_cs_bitonic_sort.SetBuffer(1, "consts", m_buf_consts[0]);
                m_cs_bitonic_sort.SetBuffer(1, "kip", kip_tmp);
                m_cs_bitonic_sort.SetBuffer(1, "kip_rw", kip);
                m_cs_bitonic_sort.Dispatch(1, (int)(MATRIX_HEIGHT / TRANSPOSE_BLOCK_SIZE), (int)(MATRIX_WIDTH / TRANSPOSE_BLOCK_SIZE), 1);
    
                // Sort the row data
                m_cs_bitonic_sort.SetBuffer(0, "consts", m_buf_consts[0]);
                m_cs_bitonic_sort.SetBuffer(0, "kip_rw", kip);
                m_cs_bitonic_sort.Dispatch(0, (int)(NUM_ELEMENTS / BITONIC_BLOCK_SIZE), 1, 1);
            }
        }
    }
}
