class logger
{
	static void log(Char, A...)(in Char[] fmt, A args)
	{
		writefln(fmt,args);
	}
}
