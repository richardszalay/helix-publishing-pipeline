using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Xml;
using Xunit;

namespace RichardSzalay.Helix.Publishing.Tasks.Tests
{
    public class MergeXmlTransformsTests
    {
        [Fact]
        public void NoTransforms_ReturnsTrue()
        {
            TestTransformTask(true, null, new string[0], "");
        }

        [Fact]
        public void InvalidTransforms_ReturnsFalse()
        {
            TestTransformTask(false, null, new string[] { "<configuration" }, "<configuration />");
        }

        [Fact]
        public void ValidTransforms_MergedRootElementChildren()
        {
            TestTransformTask(
                true,
                @"<configuration>
                    <appSettings>
                        <add key=""Transform1.Key1"" value=""Transform1.Value1"" xdt:Transform=""Insert"" xmlns:xdt=""http://schemas.microsoft.com/XML-Document-Transform"" />
                    </appSettings>
                    <appSettings>
                        <add key=""Transform2.Key2"" value=""Transform2.Value2"" xdt:Transform=""Insert"" xmlns:xdt=""http://schemas.microsoft.com/XML-Document-Transform"" />
                    </appSettings>
                 </configuration>
                ", 
                new string[]
                {
                    @"<configuration xmlns:xdt=""http://schemas.microsoft.com/XML-Document-Transform"">
                        <appSettings>
                            <add key=""Transform1.Key1"" value=""Transform1.Value1"" xdt:Transform=""Insert"" />
                        </appSettings>
                     </configuration>
                    ",
                    @"<configuration xmlns:xdt=""http://schemas.microsoft.com/XML-Document-Transform"">
                        <appSettings>
                            <add key=""Transform2.Key2"" value=""Transform2.Value2"" xdt:Transform=""Insert"" />
                        </appSettings>
                     </configuration>
                    ",
                },
                targetContent: @"<configuration />"
                );
        }

        static void TestTransformTask(bool expectedResult, string expectedOutput, string[] inputTransforms, string targetContent)
        {
            var task = new MergeXmlTransforms();

            var targetFile = CreateTempFile(targetContent);

            var inputTransformFiles = inputTransforms
                .Select(CreateTempFile)
                .ToList();

            var outputFile = Path.GetTempFileName();

            try
            {
                task.Target = new TaskItem(targetFile);

                task.Transforms = inputTransformFiles
                    .Select(path => new TaskItem(path))
                    .ToArray();

                task.OutputPath = outputFile;

                task.BuildEngine = new FakeBuildEngine();

                var result = task.Execute();



                Assert.Equal(expectedResult, result);

                if (expectedResult)
                {
                    var expected = NormalizeXml(expectedOutput);
                    var actual = NormalizeXml(File.ReadAllText(outputFile));

                    Assert.Equal(expected, actual);
                }
            }
            finally
            {
                foreach (var inputTransformFile in inputTransformFiles)
                {
                    try
                    {
                        File.Delete(inputTransformFile);
                    }
                    catch
                    {

                    }
                }

                try
                {
                    File.Delete(outputFile);
                }
                catch
                {

                }
            }
        }

        static string CreateTempFile(string contents)
        {
            var filename = Path.GetTempFileName();
            File.WriteAllText(filename, contents);
            return filename;
        }

        static string NormalizeXml(string input)
        {
            var doc = new XmlDocument();
            doc.PreserveWhitespace = false;
            doc.LoadXml(input);

            using (var buffer = new StringWriter())
            using (var writer = new XmlTextWriter(buffer))
            {
                writer.Formatting = Formatting.None;
                doc.Save(writer);

                return buffer.ToString();
            }
        }
    }
}
