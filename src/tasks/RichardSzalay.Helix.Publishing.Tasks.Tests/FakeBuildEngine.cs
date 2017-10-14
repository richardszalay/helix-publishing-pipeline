using System.Collections;
using Microsoft.Build.Framework;
using System.Collections.Generic;

namespace RichardSzalay.Helix.Publishing.Tasks.Tests
{
    internal class FakeBuildEngine : IBuildEngine
    {
        public bool ContinueOnError { get; set; }

        public int LineNumberOfTaskNode { get; set; }

        public int ColumnNumberOfTaskNode { get; set; }

        public string ProjectFileOfTaskNode { get; set; }

        public bool BuildProjectFile(string projectFileName, string[] targetNames, IDictionary globalProperties, IDictionary targetOutputs)
        {
            throw new System.NotImplementedException();
        }

        public List<CustomBuildEventArgs> LoggedCustomEvents = new List<CustomBuildEventArgs>();
        public void LogCustomEvent(CustomBuildEventArgs e)
        {
            LoggedCustomEvents.Add(e);
        }

        public List<BuildErrorEventArgs> LoggedErrorEvents = new List<BuildErrorEventArgs>();
        public void LogErrorEvent(BuildErrorEventArgs e)
        {
            LoggedErrorEvents.Add(e);
        }

        public List<BuildMessageEventArgs> LoggedMessageEvents = new List<BuildMessageEventArgs>();
        public void LogMessageEvent(BuildMessageEventArgs e)
        {
            LoggedMessageEvents.Add(e);
        }

        public List<BuildWarningEventArgs> LoggedWarningEvents = new List<BuildWarningEventArgs>();
        public void LogWarningEvent(BuildWarningEventArgs e)
        {
            LoggedWarningEvents.Add(e);
        }
    }
}
