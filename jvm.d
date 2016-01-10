import std.stdio;
import std.array;
import std.string;

import classloader.loader;
import vm.constantpool;

void main(string[] args)
{
	//load file
	if(args.length > 0)
	{
		loader l = new loader();
		cp_info[] constant_pool = l.load(args[1]);
		
		
	}
}
