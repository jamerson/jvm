module classloader.byte_stream;

import std.bitmanip;

public class byte_stream
{
	private ubyte _bytes[];
	private uint _index = 0;
	public this(ubyte bytes[])
	{
		_bytes = bytes;
	}
	
	ubyte get_next_byte()
	{
		ubyte result = 0;
		//log("current position %d",_index);
		if(_index+1 < _bytes.length) 
			result = _bytes[_index++]; 	
		return result;
	}
	
	uint get_next_int()
	{
		ubyte result[];
		ubyte type_size = 4;
		result.length = type_size;
		//log("current position %d",_index);
		if(_index + type_size < _bytes.length) {
			for(int i = 0; i < type_size; i++)
			{
				result[i] = get_next_byte();
			}
		} 	
		return result.read!uint();
	}
	
	ushort get_next_short()
	{
		ubyte result[];
		ubyte type_size = 2;
		result.length = type_size;
		//log("current position %d",_index);
		if(_index + type_size < _bytes.length) {
			for(int i = 0; i < type_size; i++)
			{
				result[i] = get_next_byte();
			}
		} 	
		return result.read!ushort();
	}
	
	void jump_n_bytes(uint n)
	{
		_index += n;
		//log("current position %d",_index);
	}
}
