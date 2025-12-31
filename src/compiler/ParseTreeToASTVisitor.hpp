#pragma once

#include "garnish/scdsk/v0/scdskVisitor.h"
namespace garnish {
using ScdskParser = garnish::scdsk::v0::scdskParser;
/// @brief A visitor that walks the parse tree and generates an AST.
class ParseTreeToASTVisitor : public garnish::scdsk::v0::scdskVisitor {
   public:
    std::any visitFile(ScdskParser::FileContext *context) final {
        return visitChildren(context);
    }

    std::any visitStmt(ScdskParser::StmtContext *context) final {
        return visitChildren(context);
    }

    std::any visitReal(ScdskParser::RealContext *context) final {
        return visitChildren(context);
    }
    
    std::any visitId(ScdskParser::IdContext *context) final {
        return visitChildren(context);
    }

    std::any visitString(ScdskParser::StringContext *context) final {
        return visitChildren(context);
    }
};
}  // namespace garnish