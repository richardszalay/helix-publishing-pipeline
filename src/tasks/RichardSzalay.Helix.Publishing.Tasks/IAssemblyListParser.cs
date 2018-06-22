using System.Collections.Generic;
using System.IO;

namespace RichardSzalay.Helix.Publishing.Tasks
{
    public interface IAssemblyListParser
    {
        IEnumerable<AssemblyListEntry> Parse(TextReader textReader);
    }
}