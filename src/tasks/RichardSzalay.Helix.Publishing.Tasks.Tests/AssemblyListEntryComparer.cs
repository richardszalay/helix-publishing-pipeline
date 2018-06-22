using System;
using System.Collections.Generic;

namespace RichardSzalay.Helix.Publishing.Tasks.Tests
{
    public class AssemblyListEntryComparer : IEqualityComparer<AssemblyListEntry>
    {
        public bool Equals(AssemblyListEntry x, AssemblyListEntry y)
        {
            return x.Assembly == y.Assembly &&
                x.FileVersion == y.FileVersion &&
                x.AssemblyVersion == y.AssemblyVersion;
        }

        public int GetHashCode(AssemblyListEntry obj)
        {
            throw new NotImplementedException();
        }
    }
}
