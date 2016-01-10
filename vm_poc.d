import std.stdio;
import std.array;
import std.stream;
import std.string;

//JAVA bytecodes
int oc_aload_0 = 0x2a;
int oc_invokespecial = 0xb7;
int oc_return = 0xb1;
int oc_getstatic = 0xb2;
int oc_ldc = 0x12;
int oc_invokevirtual = 0xb7;

class cpu
{
	static int _stack[255] ;
	static byte _stack_pointer = 0;
	
	static void run(int opcode, int n)
	{
		switch(opcode)
		{
			case oc_aload_0:
				writefln("aload_0 %d",n);
				break;
			case oc_invokespecial:
				writefln("invokespecial %d",n);
				break;
			case oc_return:
				writefln("return %d",n);
				break;
			case oc_getstatic:
				writefln("getstatic %d",n);
				break;
			case oc_ldc:
				writefln("ldc %d",n);
				break;
			case oc_invokevirtual:
				writefln("invokevirtual %d",n);
				break;
			default:
				writeln("Unknown opcode");
		}
	}
}

class process
{
	int _program[255][2];
	ubyte _pc = 0;
	
	void add_instruction(int opcode, int n)
	{
		_program[_pc][0]= opcode;
		_program[_pc][1] = n;
		_pc += 1;
	}
	
	void start()
	{
		int opcode;
		int n;
		for(int i=0;i < _pc;i++)
		{
			opcode = _program[i][0];
			n = _program[i][1];
			cpu.run(opcode,n);	
		}
		_pc = 0;
	}
}

void compile(string filename)
{
	bool constant_pool = false;
	Stream file = new BufferedFile(filename);
	foreach(ulong n, char[] line; file)
	{
		if(line.indexOf("Constant pool:") == 0)
		{
			constant_pool = true;
		} else if(line.indexOf("{") == 0) 
		{
			constant_pool = false;
		}
	}
	file.close();
}

void main(string[] args)
{
	//initialize internal state
	auto p = new process();
	
	//load file
	if(args.length > 0)
	{
		compile(args[1]);
	}
	
	//execute code
	p.start();
}