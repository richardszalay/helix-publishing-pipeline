using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace RichardSzalay.Helix.Publishing.Tasks
{
    public class AssemblyListParser : IAssemblyListParser
    {
        public IEnumerable<AssemblyListEntry> Parse(TextReader textReader)
        {
            Func<string> lineReader = () => ReadNonEmptyLine(textReader);

            if (!TryReadHeader(lineReader, out var headers, out var options))
            {
                yield break;
            }

            while (TryReadEntry(lineReader, options, headers, out var entry))
            {
                yield return entry;
            }
        }

        private bool TryReadEntry(Func<string> readNonEmptyLine, AssemblyListOptions options, string[] headers, out AssemblyListEntry entry)
        {
            entry = null;

            var line = readNonEmptyLine();

            if (line == null)
                return false;

            var parsedLine = ParseLine(line, options);

            // TODO: Should we use headers? Investigate available lists for header-consistency

            if (parsedLine.Length != 3)
            {
                return false;
            }

            entry = new AssemblyListEntry
            {
                Assembly = parsedLine[0],
                FileVersion = parsedLine[1],
                AssemblyVersion = parsedLine[2]
            };
            return true;
        }

        private string ReadNonEmptyLine(TextReader reader)
        {
            string line = reader.ReadLine();

            while (line != null && line == string.Empty)
            {
                line = reader.ReadLine();
            }

            return line;
        }

        private bool TryReadHeader(Func<string> readNonEmptyLine, out string[] headers, out AssemblyListOptions options)
        {
            headers = null;
            options = null;

            var line = readNonEmptyLine();

            if (line == null)
                return false;

            if (TryParseOptions(line, out options))
            {
                line = readNonEmptyLine();
            }

            if (line == null)
                return false;

            if (options == null)
            {
                var separator = GuessSeparator(line);

                if (separator == null)
                {
                    // TODO: Log
                    return false;
                }

                options = new AssemblyListOptions
                {
                    Separator = GuessSeparator(line)
                };
            }

            headers = ParseLine(line, options);
            return true;
        }

        private string[] ParseLine(string line, AssemblyListOptions options)
        {
            return line.Split(new[] { options.Separator }, StringSplitOptions.None);
        }

        private string GuessSeparator(string headerLine)
        {
            if (headerLine.Contains('|'))
                return "|";

            if (headerLine.Contains(','))
                return ",";

            throw new ArgumentException("Unable to determine separator");
        }

        private bool TryParseOptions(string line, out AssemblyListOptions options)
        {
            options = null;

            if (string.IsNullOrEmpty(line))
                return false;

            if (!line.StartsWith("sep=") || line.Length < "sep=".Length + 1)
                return false;

            var separator = line.Substring("sep=".Length);

            options = new AssemblyListOptions
            {
                Separator = separator
            };

            return true;
        }

        class AssemblyListOptions
        {
            public string Separator;

            public static AssemblyListOptions Default =>
                new AssemblyListOptions { Separator = "," };
        }
    }
}
