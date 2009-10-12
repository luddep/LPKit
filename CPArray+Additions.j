@implementation CPArray (Additions)

- (int)_LPmaxValue
{
    var max = 0;
    for (var i=0; i<[self count]; i++)
    {
        current = [self objectAtIndex:i];
        if (current > max)
            max = current
    }
    return max;
}

- (void)_LPreverse
{
    var i = 0,
        j = [self count] - 1;
    
    while (i < j)
    {
        [self exchangeObjectAtIndex:i withObjectAtIndex:j];
        i++;
        j--;
    }
}

@end