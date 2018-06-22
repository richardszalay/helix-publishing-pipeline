using Microsoft.Build.Framework;
using System.Collections.Generic;
using System.IO;
using Xunit;

namespace RichardSzalay.Helix.Publishing.Tasks.Tests
{
    public class AssemblyListParserTests
    {
        private readonly AssemblyListParser sut;

        public AssemblyListParserTests()
        {
            sut = new AssemblyListParser();
        }

        void Test(string input, List<AssemblyListEntry> expected)
        {
            var actual = sut.Parse(new StringReader(input));

            Assert.Equal(expected, actual, new AssemblyListEntryComparer());
        }

        [Fact]
        public void NoOptionsRow_NoHeaderRow_ReturnsNothing()
        {
            Test(
                input: @"",
                expected: new List<AssemblyListEntry>()
            );
        }

        [Fact]
        public void NoOptionsRow_CommaDelimitedHeaderRow_ParsesUsingCommas()
        {
            Test(
                input: @"A,B,C
Asm,1.0,2.0",
                expected: new List<AssemblyListEntry>
                {
                    CreateAssemblyListEntry("Asm", "1.0", "2.0")
                }
            );
        }

        [Fact]
        public void NoOptionsRow_PipeDelimitedHeaderRow_ParsesUsingPipes()
        {
            Test(
                input: @"A|B|C
Asm|1.0|2.0",
                expected: new List<AssemblyListEntry>
                {
                    CreateAssemblyListEntry("Asm", "1.0", "2.0")
                }
            );
        }

        [Fact]
        public void OptionsRow_UsesDelimiterFromOptionsRow()
        {
            Test(
                input: @"sep=|
A|B|C
Asm|1.0|2.0",
                expected: new List<AssemblyListEntry>
                {
                    CreateAssemblyListEntry("Asm", "1.0", "2.0")
                }
            );
        }

        [Fact]
        public void ParsingRows_OneEntryForEachRow()
        {
            Test(
                input: @"A,B,C
Asm1,1.0,2.0
Asm2,2.0,3.0
Asm3,3.0,4.0",

                expected: new List<AssemblyListEntry>
                {
                    CreateAssemblyListEntry("Asm1", "1.0", "2.0"),
                    CreateAssemblyListEntry("Asm2", "2.0", "3.0"),
                    CreateAssemblyListEntry("Asm3", "3.0", "4.0")
                }
            );
        }

        [Fact]
        public void OutOfOrderHeaders_AreIgnored()
        {
            Test(
                input: @"FileVersion,AssemblyVersion,Assembly
Asm1,1.0,2.0",

                expected: new List<AssemblyListEntry>
                {
                    CreateAssemblyListEntry("Asm1", "1.0", "2.0")
                }
            );
        }

        [Fact]
        public void EmptyRows_AreSkipped()
        {
            Test(
                input: @"FileVersion,AssemblyVersion,Assembly
Asm1,1.0,2.0

Asm2,2.0,3.0",

                expected: new List<AssemblyListEntry>
                {
                    CreateAssemblyListEntry("Asm1", "1.0", "2.0"),
                    CreateAssemblyListEntry("Asm2", "2.0", "3.0")
                }
            );
        }

        [Fact]
        public void InvalidRows_StopsProcessing()
        {
            Test(
                input: @"FileVersion,AssemblyVersion,Assembly
Asm1,1.0,2.0
Asm2
Asm3,3.0,4.0",

                expected: new List<AssemblyListEntry>
                {
                    CreateAssemblyListEntry("Asm1", "1.0", "2.0")
                }
            );
        }

        static AssemblyListEntry CreateAssemblyListEntry(string assembly, string fileVersion, string assemblyVersion)
        {
            return new AssemblyListEntry
            {
                Assembly = assembly,
                FileVersion = fileVersion,
                AssemblyVersion = assemblyVersion
            };
        }
    }
}
