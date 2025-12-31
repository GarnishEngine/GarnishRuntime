#pragma once

// #include "AST/ASTNode.h"

namespace garnish {

template <typename Derived>
class PassVisitor {
   public:
    // void visit(ExprNode &node) {
    //     std::visit([this](auto &n) { derived().visit(n); }, node);
    // }
    // 
    // void visit(StmtNode &node) {
    //     std::visit([this](auto &n) { derived().visit(n); }, node);
    // }

    // void visit(std::shared_ptr<ASTModule> &module) {
    //     for (auto &stmt : module->statements) {
    //         visit(stmt);
    //     }
    // }

    // Expression visit methods
    // Literals
    // void visit(std::shared_ptr<IntLiteralNode> &node) {
    //     // Leaf node - no children to traverse
    // }

    // void visit(std::shared_ptr<RealLiteralNode> &node) {
    //     // Leaf node - no children to traverse
    // }

   protected:
    Derived &derived() { return static_cast<Derived &>(*this); }
};

}  // namespace gazprea