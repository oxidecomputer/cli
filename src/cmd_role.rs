use anyhow::Result;
use clap::Parser;
use cli_macro::crud_gen;

/// Manage built-in roles.
#[derive(Parser, Debug, Clone)]
#[clap(verbatim_doc_comment)]
pub struct CmdRole {
    #[clap(subcommand)]
    subcmd: SubCommand,
}

#[crud_gen {
    tag = "roles",
}]
#[derive(Parser, Debug, Clone)]
enum SubCommand {}

#[async_trait::async_trait]
impl crate::cmd::Command for CmdRole {
    async fn run(&self, ctx: &mut crate::context::Context) -> Result<()> {
        match &self.subcmd {
            SubCommand::List(cmd) => cmd.run(ctx).await,
            SubCommand::View(cmd) => cmd.run(ctx).await,
        }
    }
}
