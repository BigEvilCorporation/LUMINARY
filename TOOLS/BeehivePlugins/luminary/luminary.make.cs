using Sharpmake;
using System.IO;

[Generate]
class Luminary : IonLib
{
    public Luminary() : base("luminary")
    {
        AddTargets(Globals.IonTargetsDefault);
    }

    [Configure]
    public override void Configure(Project.Configuration conf, Target target)
    {
        base.Configure(conf, target);

        conf.Defines.Add("BEEHIVE_PLUGIN_LUMINARY=1");
        conf.ExportDefines.Add("BEEHIVE_PLUGIN_LUMINARY=1");

        conf.IncludePaths.Add(@"[project.SharpmakeCsPath]/..");
    }
}