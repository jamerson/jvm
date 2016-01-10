module classloader.loader;

import std.stream;
import std.string;
import std.array;
import std.file;
import std.stdio;
import std.bitmanip;

import vm.constantpool;
import classloader.byte_stream;
import classloader.codeloader;

void log(Char, A...)(in Char[] fmt, A args)
{
	writefln(fmt,args);
}

class loader
{
	cp_info _constant_pool[];
	
	private CONSTANT_ref_info get_ref_info(ubyte tag,byte_stream stream)
	{
		CONSTANT_ref_info item;
		switch(tag){
			case tag_types.CONSTANT_Methodref:
				item = new CONSTANT_Methodref_info();
				break;
			case tag_types.CONSTANT_Fieldref:
				item = new CONSTANT_Fieldref_info();
				break;
			case tag_types.CONSTANT_InterfaceMethodref:
				item = new CONSTANT_InterfaceMethodref_info();
				break;
			default:
				break;
		}
		item.class_index = [stream.get_next_byte(), stream.get_next_byte()];	
		item.name_and_type_index = [stream.get_next_byte(), stream.get_next_byte()];
		log("Ref");
		
		return item;
	}
	
	private CONSTANT_Class_info get_class(byte_stream stream)
	{
		auto item = new CONSTANT_Class_info();
		item.name_index = [stream.get_next_byte(), stream.get_next_byte()];
		
		log("Class");
		
		return item;
	}
	
	private CONSTANT_String_info get_string(byte_stream stream)
	{
		CONSTANT_String_info item = new CONSTANT_String_info();
		item.string_index = [stream.get_next_byte(), stream.get_next_byte()];
		log("String");
		
		return item;
	}
	
	private CONSTANT_Number_info get_number(ubyte tag, byte_stream stream)
	{
		CONSTANT_Number_info item;
		
		switch(tag)
		{
			case tag_types.CONSTANT_Integer:
			item = new CONSTANT_Integer_info();
			break;
			case tag_types.CONSTANT_Float:
			item = new CONSTANT_Float_info();
			break;
			default:
			break;
		}
		item.bytes = [stream.get_next_byte(), stream.get_next_byte(), stream.get_next_byte(), stream.get_next_byte()];
		log("Number");
		
		return item;
	}
	
	private CONSTANT_LNumber_info get_long_number(ubyte tag, byte_stream stream)
	{
		CONSTANT_LNumber_info item;
		
		switch(tag)
		{
			case tag_types.CONSTANT_Long:
			item = new CONSTANT_Long_info();
			break;
			case tag_types.CONSTANT_Double:
			item = new CONSTANT_Double_info();
			break;
			default:
			break;
		}
		item.high_bytes = [stream.get_next_byte(), stream.get_next_byte(), stream.get_next_byte(), stream.get_next_byte()];
		item.low_bytes = [stream.get_next_byte(), stream.get_next_byte(), stream.get_next_byte(), stream.get_next_byte()];
		log("Long Number");
		
		return item;
	}
	
	private CONSTANT_NameAndType_info get_name_and_type(byte_stream stream)
	{
		CONSTANT_NameAndType_info item = new CONSTANT_NameAndType_info();
		item.name_index = [stream.get_next_byte(), stream.get_next_byte()];
		item.descriptor_index = [stream.get_next_byte(), stream.get_next_byte()];
		log("NameAndType");
		
		return item;
	}
	
	private CONSTANT_Utf8_info get_utf8(byte_stream stream)
	{
		CONSTANT_Utf8_info item = new CONSTANT_Utf8_info();
		item.length = [stream.get_next_byte(), stream.get_next_byte()];
		ubyte string_length_array[] = item.length;
		ushort length = string_length_array.read!ushort();
		for(ushort i = 0; i < length && i < 256; i++)
		{
			item.bytes[i] = stream.get_next_byte();
		}
		log("Utf8 %s",cast(char[])item.bytes);
		
		return item;
	}
	
	private cp_info get_const_pool_item(byte_stream stream)
	{
		ubyte tag = stream.get_next_byte();
		cp_info item = new cp_info();
		item.tag = tag;
		switch(tag){
			case tag_types.CONSTANT_Fieldref:
			case tag_types.CONSTANT_Methodref:
			case tag_types.CONSTANT_InterfaceMethodref:
				item.info = get_ref_info(tag,stream);
				break;
			case tag_types.CONSTANT_String:
				item.info = get_string(stream);
				break;
			case tag_types.CONSTANT_Class:
				item.info = get_class(stream);
				break;
			case tag_types.CONSTANT_Utf8:
				item.info = get_utf8(stream);
				break;
			case tag_types.CONSTANT_NameAndType:
				item.info = get_name_and_type(stream);
				break;
			case tag_types.CONSTANT_Integer:
			case tag_types.CONSTANT_Float:
				item.info = get_number(tag, stream);
				break;
			case tag_types.CONSTANT_Long:
			case tag_types.CONSTANT_Double:
				item.info = get_long_number(tag, stream);
				break;
			default:
				break;
		}
		
		return item;
	}
	
	private bool is_class_file(byte_stream stream)
	{
		if(stream.get_next_byte() == 0xCA &&
			stream.get_next_byte() == 0xFE &&
			stream.get_next_byte() == 0xBA &&
			stream.get_next_byte() == 0xBE)
			return true;
		return false;
	}
	
	private ushort get_counter(byte_stream stream)
	{
		ubyte count_buffer[] = [stream.get_next_byte(), stream.get_next_byte()];
		return count_buffer.read!ushort();
	}
	
	private void jump_info(byte_stream stream)
	{
		/*CONSTANT_Utf8_info {
				u1 tag;*/
		stream.get_next_byte();	
				/*u2 length;*/
		ushort bytes_length = get_counter(stream);
				/*u1 bytes[length];
			}*/
		stream.jump_n_bytes(bytes_length);
	}

	private void get_attribute(byte_stream stream)
	{
		/*attribute_info {
				u2 attribute_name_index;*/
		ushort name_index = stream.get_next_short();
				/*u4 attribute_length;*/
		uint attribute_length = stream.get_next_int();
		cp_info cpi = _constant_pool[name_index - 1];
		uint used_bytes = 0;
		if(cpi.tag == tag_types.CONSTANT_Utf8)
		{
			CONSTANT_Utf8_info utf8_info = cast(CONSTANT_Utf8_info)cpi.info;
			ubyte info_length_buffer[] = utf8_info.length;
			ushort info_length = info_length_buffer.read!ushort();
			
			if(utf8_info.length == [0x0,0x4])
			{
				
				if(utf8_info.bytes[0..4] == "Code")
				{
					
					/*Code_attribute {
						u2 attribute_name_index; - already consumed
						u4 attribute_length; - already consumed
						u2 max_stack;
						u2 max_locals;*/
						stream.jump_n_bytes(4);
						used_bytes+=4;
						/*u4 code_length;*/
						uint code_length = stream.get_next_int();
						used_bytes+=4;
						/*u1 code[code_length];*/
						code_loader c = new code_loader();
						c.get_code(code_length, stream);
						used_bytes+=code_length;
						/*
						u2 exception_table_length;
						{   u2 start_pc;
							u2 end_pc;
							u2 handler_pc;
							u2 catch_type;
						} exception_table[exception_table_length];
						u2 attributes_count;
						attribute_info attributes[attributes_count];
					}*/
				}
			}
		}
		
		stream.jump_n_bytes(attribute_length - used_bytes);
	}
	
	private void get_method(byte_stream stream)
	{
		/*method_info {
			u2             access_flags;
			u2             name_index;
			u2             descriptor_index;*/
			stream.jump_n_bytes(6);
			/*u2             attributes_count;*/
			ushort attributes_count = get_counter(stream);
			log("number of attributes: %d",attributes_count);
			for(ushort i = 0; i < attributes_count;i++)
			{
				get_attribute(stream);
				/*attribute_info attributes[attributes_count];
				 * }*/
			}
		
	}
	
	private void jump_field(byte_stream stream)
	{
		/*field_info {
				u2             access_flags;
				u2             name_index;
				u2             descriptor_index;*/
		stream.jump_n_bytes(6);
		/*	u2             attributes_count;*/
		ushort attributes_count = get_counter(stream);
		
		for(ushort i = 0; i < attributes_count;i++)
		{
			/*	attribute_info attributes[attributes_count];
			}*/
			get_attribute(stream);
		}
	}
	
	public cp_info[] load(in string filename)
	{
		auto bytes = cast(ubyte[]) read(filename);
		
		byte_stream stream = new byte_stream(bytes);
		
		if(is_class_file(stream))
		{
			log("file has magic: is a java class");
			// 4, 5: minor version
			// 6, 7: major version
			stream.jump_n_bytes(4);
			// 8, 9: constant pool count
			ushort constant_pool_count = get_counter(stream);
			log("the size of constant pool is %d",constant_pool_count);
			
			_constant_pool.length = constant_pool_count - 1;
			//10 .. *: constant pool items
			for(ushort i = 0; i < _constant_pool.length;i++)
			{
				_constant_pool[i] = get_const_pool_item(stream);
			}
			//u2: access_flags;
			stream.jump_n_bytes(2);
			//u2: this_class;
			ubyte this_class[] = [stream.get_next_byte(), stream.get_next_byte()];
			//u2: super_class;
			stream.jump_n_bytes(2);
			//u2: interfaces_count;
			ushort interfaces_count = get_counter(stream);
			log("the number of interfaces is %d",interfaces_count);
			
			//interfaces[interfaces_count];
			//interfaces are CONSTANT_Class_info Structures
			stream.jump_n_bytes((new CONSTANT_Class_info()).sizeof * interfaces_count);
			
			//u2: fields_count;
			ushort fields_count = get_counter(stream);
			log("the number of fields is %d",fields_count);
			for(ushort i = 0; i < fields_count;i++)
			{
				jump_field(stream);
			}
			//u2: methods_count;
			ushort methods_count = get_counter(stream);
			log("the number of methods is %d",methods_count);
			//method_info    methods[methods_count];
			for(ushort i = 0; i < methods_count;i++)
			{
				get_method(stream);
			}
			
			return _constant_pool;
		}
		
		return null;
	}
}
