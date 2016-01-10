module vm.constantpool;

enum tag_types: ubyte { 
	CONSTANT_Class = 7,
	CONSTANT_Fieldref = 9,
	CONSTANT_Methodref = 10,
	CONSTANT_InterfaceMethodref = 11,
	CONSTANT_String = 8,
	CONSTANT_Integer = 3,
	CONSTANT_Float = 4,
	CONSTANT_Long = 5,
	CONSTANT_Double = 6,
	CONSTANT_NameAndType = 12,
	CONSTANT_Utf8 = 1
}

class CONSTANT_info {
	ubyte tag = 0;
}

class CONSTANT_Class_info: CONSTANT_info {
	this() {
		tag = tag_types.CONSTANT_Class;
	}
	ubyte name_index[2];
}

class CONSTANT_ref_info: CONSTANT_info {
	byte class_index[2];
	byte name_and_type_index[2];
}

class CONSTANT_Fieldref_info: CONSTANT_ref_info {
	this() {
		tag = tag_types.CONSTANT_Fieldref;
	}
}

class CONSTANT_Methodref_info: CONSTANT_ref_info {
	this() {
		tag = tag_types.CONSTANT_Methodref;
	}
}

class CONSTANT_InterfaceMethodref_info: CONSTANT_ref_info {
	this() {
		tag = tag_types.CONSTANT_InterfaceMethodref;
	}
}

class CONSTANT_String_info: CONSTANT_info {
	this() {
		tag = tag_types.CONSTANT_String ;
	}
	ubyte string_index[2];
}

class CONSTANT_Number_info: CONSTANT_info {
	ubyte bytes[4];
}

class CONSTANT_Integer_info: CONSTANT_Number_info {
	this() {
		tag = tag_types.CONSTANT_Integer;
	}
}

class CONSTANT_Float_info: CONSTANT_Number_info {
	this() {
		tag = tag_types.CONSTANT_Float ;
	}
}

class CONSTANT_LNumber_info: CONSTANT_info {
	ubyte high_bytes[4];
	ubyte low_bytes[4];
}

class CONSTANT_Long_info: CONSTANT_LNumber_info {
	this() {
		tag = tag_types.CONSTANT_Long;
	}
}

class CONSTANT_Double_info: CONSTANT_LNumber_info {
	this() {
		tag = tag_types.CONSTANT_Double;
	}
}

class CONSTANT_NameAndType_info: CONSTANT_info {
	this() {
		tag = tag_types.CONSTANT_NameAndType;
	}
	ubyte name_index[2];
	ubyte descriptor_index[2];
}

class CONSTANT_Utf8_info: CONSTANT_info {
	this() {
		tag = tag_types.CONSTANT_Utf8;
	}
	ubyte length[2];
	ubyte bytes[256];
}

class cp_info {
	byte tag;
	CONSTANT_info info;
}

class attribute_info {
    ubyte[2] attribute_name_index;
    ubyte[4] attribute_length;
}

class Code_attribute: attribute_info {
    ubyte[2] max_stack;
    ubyte[2] max_locals;
    ubyte[4] code_length;
    ubyte code[256];
}
