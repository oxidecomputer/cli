use anyhow::Result;
use clap::Parser;
use cli_macro::crud_gen;

/// Create, list, view, and delete images.
#[derive(Parser, Debug, Clone)]
#[clap(verbatim_doc_comment)]
pub struct CmdImage {
    #[clap(subcommand)]
    subcmd: SubCommand,
}

#[crud_gen {
    tag = "images",
}]
#[derive(Parser, Debug, Clone)]
enum SubCommand {
    Global(crate::cmd_image_global::CmdImageGlobal),
}

#[async_trait::async_trait]
impl crate::cmd::Command for CmdImage {
    async fn run(&self, ctx: &mut crate::context::Context) -> Result<()> {
        match &self.subcmd {
            SubCommand::Create(cmd) => cmd.run(ctx).await,
            SubCommand::Delete(cmd) => cmd.run(ctx).await,
            SubCommand::List(cmd) => cmd.run(ctx).await,
            SubCommand::View(cmd) => cmd.run(ctx).await,
            SubCommand::Global(cmd) => cmd.run(ctx).await,
        }
    }
}
