using System;
using System.Collections.Generic;
using System.IO;
using System.Text;

namespace RichardSzalay.Helix.Publishing.Tasks.Tests
{
    public class FakeAssemblyParser : IAssemblyListParser
    {
        public Dictionary<string, List<AssemblyListEntry>> Files = new Dictionary<string, List<AssemblyListEntry>>();

        public IEnumerable<AssemblyListEntry> Parse(TextReader textReader)
        {
            var content = textReader.ReadToEnd();

            if (Files.ContainsKey(content))
                return Files[content];

            return Array.Empty<AssemblyListEntry>();
        }
    }
}
