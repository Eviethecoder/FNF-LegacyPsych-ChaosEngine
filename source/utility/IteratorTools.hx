package utility;

class IteratorTools
{
  public static function array<T>(iterator:Iterator<T>):Array<T>
  {
    return [for (i in iterator) i];
  }

}

