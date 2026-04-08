Class Tameshi.C1 Extends %RegisteredObject
{

Property P1 As %String;

ClassMethod M3()
{
    set sys=##class(%SYS.Python).Import("sys")
    do sys.path.append("/src")
    set tameshi=##class(%SYS.Python).Import("tameshi")
    set modori=tameshi.test2()
    write modori."__getitem__"(0),! ; "a"と表示されるはず
    write modori."__getitem__"(1) ; "b"と表示される
}

ClassMethod M4()
{
    set sys=##class(%SYS.Python).Import("sys")
    do sys.path.append("/src")
    set tameshi=##class(%SYS.Python).Import("tameshi")
    set map=$LISTBUILD($LISTBUILD())

    set modori=tameshi.test3(.a)
}

ClassMethod M1()
{
    set o=..%New()
    set o.P1="あいうえお"
    set sys=##class(%SYS.Python).Import("sys")
    do sys.path.append("/src")
    set tameshi=##class(%SYS.Python).Import("tameshi")
    do tameshi.test(o)
}

Method M2()
{
    set o=..%New()
    set o.P1="あいうえお"
    set sys=##class(%SYS.Python).Import("sys")
    do sys.path.append("/src")
    set tameshi=##class(%SYS.Python).Import("tameshi")
    do tameshi.test($this)
}

}
