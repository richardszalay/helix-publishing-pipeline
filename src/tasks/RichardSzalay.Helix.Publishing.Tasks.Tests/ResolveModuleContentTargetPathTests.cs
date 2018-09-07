using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Xunit;

namespace RichardSzalay.Helix.Publishing.Tasks.Tests
{
    public class ResolveModuleContentTargetPathTests
    {
        private readonly ResolveModuleContentTargetPath sut;

        public ResolveModuleContentTargetPathTests()
        {
            sut = new ResolveModuleContentTargetPath()
            {
                ModuleMetadataPrefix = "HelixModule",
                TargetPathMetadataName = "TargetPath",
                BuildEngine = new FakeBuildEngine()
            };
        }

        [Fact]
        public void Uses_relative_path_when_no_TargetPath_specified()
        {
            Test(
                CreateModuleItem(@"c:\path\to\TestModule.csproj"),
                new[]
                {
                    CreateContentItem(@"c:\path\to\relative\content1.txt"),
                    CreateContentItem(@"c:\path\to\relative\content2.txt")
                },
                success: true,
                expectedTargetPaths: new[]
                {
                    @"relative\content1.txt",
                    @"relative\content2.txt"
                }
            );
        }

        [Fact]
        public void Throws_when_no_TargetPath_specified_but_paths_cannot_be_made_relative()
        {
            Test(
                CreateModuleItem(@"c:\path\to\TestModule.csproj"),
                new[]
                {
                    CreateContentItem(@"d:\path\to\relative\content1.txt")
                },
                success: false,
                expectedTargetPaths: new string[0]
            );
        }

        [Fact]
        public void Expands_templated_TargetPath_when_specified()
        {
            Test(
                CreateModuleItem(@"c:\path\to\TestModule.csproj"),
                new[]
                {
                    CreateContentItem(
                        @"d:\path\to\relative\content1.txt",
                        new Dictionary<string, string>
                        {
                            ["TargetPath"] = @"^(Var1)\^(Var2)",
                            ["Var1"] = @"Value1",
                            ["Var2"] = @"Value2"
                        }
                    )
                },
                success: true,
                expectedTargetPaths: new []
                {
                    @"Value1\Value2"
                }
            );
        }

        [Fact]
        public void Templated_TargetPath_prefers_content_metadata()
        {
            Test(
                CreateModuleItem(
                    @"c:\path\to\TestModule.csproj",
                    new Dictionary<string, string>
                    {
                        ["TargetPath"] = @"^(Var1)\^(Var2)",
                        ["Var1"] = @"Module1",
                        ["Var2"] = @"Module2"
                    }
                ),
                new[]
                {
                    CreateContentItem(
                        @"d:\path\to\relative\content1.txt",
                        new Dictionary<string, string>
                        {
                            ["TargetPath"] = @"^(Var1)\^(Var2)",
                            ["Var1"] = @"Value1",
                            ["Var2"] = @"Value2"
                        }
                    )
                },
                success: true,
                expectedTargetPaths: new[]
                {
                    @"Value1\Value2"
                }
            );
        }
        
        [Fact]
        public void Templated_TargetPath_uses_module_metadata_when_requested()
        {
            Test(
                CreateModuleItem(
                    @"c:\path\to\TestModule.csproj",
                    new Dictionary<string, string>
                    {
                        ["Var1"] = @"Module1",
                        ["Var2"] = @"Module2"
                    }
                ),
                new[]
                {
                    CreateContentItem(
                        @"d:\path\to\relative\content1.txt",
                        new Dictionary<string, string>
                        {
                            ["TargetPath"] = @"^(HelixModule.Filename)\^(HelixModule.Var2)",
                            ["Var1"] = @"Value1",
                            ["Var2"] = @"Value2"
                        }
                    )
                },
                success: true,
                expectedTargetPaths: new[]
                {
                    @"TestModule\Module2"
                }
            );
        }

        [Fact]
        public void Fails_when_templated_TargetPath_is_not_relative()
        {
            Test(
                CreateModuleItem(@"c:\path\to\TestModule.csproj"),
                new[]
                {
                    CreateContentItem(
                        @"d:\path\to\relative\content1.txt",
                        new Dictionary<string, string>
                        {
                            ["TargetPath"] = @"..\another\path",
                            ["Var1"] = @"Value1",
                            ["Var2"] = @"Value2"
                        }
                    )
                },
                success: false,
                expectedTargetPaths: new string[0]
            );
        }

        [Fact]
        public void Fails_when_templated_TargetPath_is_rooted()
        {
            Test(
                CreateModuleItem(@"c:\path\to\TestModule.csproj"),
                new[]
                {
                    CreateContentItem(
                        @"d:\path\to\relative\content1.txt",
                        new Dictionary<string, string>
                        {
                            ["TargetPath"] = @"c:\another\path",
                            ["Var1"] = @"Value1",
                            ["Var2"] = @"Value2"
                        }
                    )
                },
                success: false,
                expectedTargetPaths: new string[0]
            );
        }

        private void Test(ITaskItem moduleItem, ITaskItem[] contentItems, bool success, string[] expectedTargetPaths)
        {
            sut.Module = moduleItem;
            sut.Content = contentItems;
            var result = sut.Execute();

            Assert.Equal(success, result);

            if (success)
            {
                Assert.Equal(
                    expectedTargetPaths,
                    sut.Output.Select(i => i.GetMetadata("TargetPath"))
                );
            }
        }

        private ITaskItem CreateContentItem(string path, IDictionary<string, string> metadata = null)
        {
            var item = new TaskItem(path);

            if (metadata != null)
            {
                foreach (var kvp in metadata)
                {
                    item.SetMetadata(kvp.Key, kvp.Value);
                }
            }

            return item;
        }

        private ITaskItem CreateModuleItem(string path, IDictionary<string, string> metadata = null)
        {
            var item = new TaskItem(path);

            if (metadata != null)
            {
                foreach (var kvp in metadata)
                {
                    item.SetMetadata(kvp.Key, kvp.Value);
                }
            }

            return item;
        }
    }
}
