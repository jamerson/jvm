module classloader.codeloader;

import std.stdio;
import classloader.byte_stream;

void log(Char, A...)(in Char[] fmt, A args)
{
	writefln(fmt,args);
}

class code_loader
{
	public void get_code(uint code_length, byte_stream stream)
	{
		bool has_opcode = false;
		
		log("code_length: %d",code_length);
		
		ubyte current_byte;
		for(int i = 0; i < code_length;i++)
		{
			current_byte = stream.get_next_byte();
			if(!has_opcode)
			{
				switch(current_byte)
				{
					case 0x2a: 
						log("aload_0");
					break;
					case 0xb7:
						log("invokespecial");
					break;
					case 0x12: 
					log("ldc");
					break;
					default:
					break;
				}
				has_opcode = true;
			}
		}
	}
}
