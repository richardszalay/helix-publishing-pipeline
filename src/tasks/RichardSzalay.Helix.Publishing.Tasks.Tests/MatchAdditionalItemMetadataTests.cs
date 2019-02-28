using Microsoft.Build.Framework;
using System.Linq;
using Xunit;

namespace RichardSzalay.Helix.Publishing.Tasks.Tests
{
    public class MatchAdditionalItemMetadataTests
    {
        private readonly FakeBuildEngine buildEngine;
        private readonly MatchAdditionalItemMetadata sut;

        public MatchAdditionalItemMetadataTests()
        {
            buildEngine = new FakeBuildEngine();

            sut = new MatchAdditionalItemMetadata();
            sut.BuildEngine = buildEngine;
        }

        [Fact]
        public void NoFiles_ReturnsFalse()
        {
            sut.Items = new ITaskItem[0];

            var result = sut.Execute();

            Assert.False(result);
            Assert.Single(buildEngine.LoggedErrorEvents);
        }

        [Fact]
        public void MatchedPattern_AssignsGroupNamesAsMetadata()
        {
            var items = new[]
            {
                new FakeTaskItem("file1.txt")
                {
                    { "Testing", "Do:Re:Mi" }
                }
            };

            sut.Pattern = "^(?<First>.+):(?<Second>.+):(?<Third>.+)$";
            sut.SourceMetadataName = "Testing";
            sut.Items = items;

            var result = sut.Execute();

            Assert.Equal("Do", items[0].GetMetadata("First"));
            Assert.Equal("Re", items[0].GetMetadata("Second"));
            Assert.Equal("Mi", items[0].GetMetadata("Third"));
        }

        [Fact]
        public void SourceMetadataName_DefaultsToName()
        {
            var items = new[]
            {
                new FakeTaskItem("file1.txt")
                {
                    { "Name", "Do:Re:Mi" }
                }
            };

            sut.Pattern = "^(?<First>.+):(?<Second>.+):(?<Third>.+)$";
            sut.Items = items;

            var result = sut.Execute();

            Assert.Equal("Do", items[0].GetMetadata("First"));
            Assert.Equal("Re", items[0].GetMetadata("Second"));
            Assert.Equal("Mi", items[0].GetMetadata("Third"));
        }

        [Fact]
        public void NonMatchingPattern_DoesNotAddMetadata()
        {
            var items = new[]
            {
                new FakeTaskItem("file1.txt")
                {
                    { "Testing", "Do:Re:Mi" }
                }
            };

            sut.Pattern = "(?<First>.+)/(?<Second>.+)";
            sut.SourceMetadataName = "Testing";
            sut.Items = items;

            var result = sut.Execute();

            Assert.True(result);
            Assert.DoesNotContain("First", items[0].MetadataNames.Cast<string>());
        }

        [Fact]
        public void OptionalGroup_CanBeSkipped()
        {
            var items = new[]
            {
                new FakeTaskItem("file1.txt")
                {
                    { "Testing", "Do" }
                }
            };

            sut.Pattern = @"(?<First>.+)(?:\:(?<Second>.+))?$";
            sut.SourceMetadataName = "Testing";
            sut.Items = items;

            var result = sut.Execute();

            Assert.True(result);
            Assert.Equal("Do", items[0].GetMetadata("First"));
            Assert.DoesNotContain("Second", items[0].MetadataNames.Cast<string>());
        }

        [Fact]
        public void InvalidPattern_FailsWithError()
        {
            var items = new[]
            {
                new FakeTaskItem("file1.txt")
                {
                    { "Testing", "Do:Re:Mi" }
                }
            };

            sut.Pattern = "(?<First";
            sut.SourceMetadataName = "Testing";
            sut.Items = items;

            var result = sut.Execute();

            Assert.False(result);
            Assert.Single(buildEngine.LoggedErrorEvents);
        }
    }
}
